# This script generate sla files to be assimilated cutting data on a domain
# defined in the grid file (see flow.cylc)
# It was developed to work inside a Cylc workflow, using its env. variables 
# The program:
# 1- control if longitude is in the correct range [-180,180] otherwise correct it. 
# 2 -controls to not generate files without data on your domain.
#
# Author: Joao Souza
# Date:   12/06/2024

import os
import xarray as xr
import pandas as pd
import numpy as np
import glob

# Read model grid and get extremities
ds = pd.read_csv(os.getenv("GRID"), header=None, delimiter=r'\s+', nrows=221572) # The nrows value was hardcoded for the AdriFs grid 
min_lat =  np.nanmin(np.asarray(ds)[:,3])
max_lat =  np.nanmax(np.asarray(ds)[:,3])
min_lon =  np.nanmin(np.asarray(ds)[:,4])
max_lon =  np.nanmax(np.asarray(ds)[:,4])

# Prepare path for satellite files
list_sat = ['Altika','Cryosat-2','HY-2B','Jason-3','Sentinel-3A','Sentinel-3B','Sentinel-6A']
sat_path = os.getenv("SAT_PATH") # get obs path from env (flow.cylc)
date     = os.getenv("START_DATE") # get cycle date from Cylc env variable

# Parse date
year = date[0:4]
month = date[4:6]
day = date[6:8]

# Look for the files containning the SLA data and process
for satellite in list_sat:
    pattern = os.path.join(sat_path, satellite, year, month, f"*{date[0:8]}*")
    files = glob.glob(pattern)
    #list_of_files.extend(files)

    ################################################
    for file in files:

        # Read obs file using xarray    
        data_xr = xr.open_dataset(file)

        # Make sure -180 <= longitude <= 180
        if data_xr.attrs['geospatial_lon_max'] > 180: 

                encoding_lon_lat = data_xr.longitude.encoding
                encoding_sla = data_xr.sla_filtered.encoding
                with xr.set_options(keep_attrs=True):
                   data_xr['longitude'] = (data_xr['longitude'] + 180) % 360 - 180
                   data_xr.longitude.encoding.update(encoding_lon_lat, inplace=True)
                   data_xr[var] = data_xr[var] + data_xr['ocean_tide']#*1000
                   data_xr[var].encoding.update(encoding_sla, inplace=True)


        # subset data based on grid extremes
        subset_ds = data_xr.where(
        (data_xr.longitude >= min_lon) & (data_xr.longitude <= max_lon) &
        (data_xr.latitude >= min_lat) & (data_xr.latitude <= max_lat),
        drop=True
        )

        if subset_ds.sla_filtered.size == 0:
            continue
        else:
            # create the NETCDF files
            subset_ds.to_netcdf(os.getenv("CYLC_SUITE_WORK_DIR") + '/../output/obs/' + satellite + '_' + year + month + day) #outfile)
        
        del data_xr, subset_ds # To amke sure it doesn't contaminate the following file