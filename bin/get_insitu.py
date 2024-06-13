# This script generate in-situ files to be assimilated cutting data on a domain
# defined in the grid file (see flow.cylc)
# It was developed to work inside a Cylc workflow, using its env. variables 
# The program:
# 1- control if longitude is in the correct range [-180,180] otherwise correct it. 
# 2 -controls to not generate files without data on your domain.
#
# Author: Joao Souza
# Date:   13/06/2024

import os
import xarray as xr
import pandas as pd
import numpy as np
import glob
import datetime

# Read model grid and get extremities
ds = pd.read_csv(os.getenv("GRID"), header=None, delimiter=r'\s+', nrows=221572) # The nrows value was hardcoded for the AdriFs grid 
min_lat =  np.nanmin(np.asarray(ds)[:,4])
max_lat =  np.nanmax(np.asarray(ds)[:,4])
min_lon =  np.nanmin(np.asarray(ds)[:,3])
max_lon =  np.nanmax(np.asarray(ds)[:,3])

# Prepare path for satellite files
list_obs = ['']
obs_path = os.getenv("INSITU_PATH") # get obs path from env (flow.cylc)
date     = os.getenv("START_DATE") # get cycle date from Cylc env variable

# Parse date
year = date[0:4]
month = date[4:6]
day = date[6:8]

# Look for the files containning the in-situ data and process (source of files change depending on date)
if datetime.datetime(int(year),int(month),int(day)) < datetime.datetime(2023,12,4):
    source = 'latest'
else:
    source = 'latest_EIS_202311'


pattern = os.path.join(obs_path, source, date[0:8], f"*")
files = glob.glob(pattern)

################################################
count = 0
for file in files:
    # Read obs file using xarray    
    data_xr = xr.open_dataset(file)

    if 'TEMP' not in data_xr: # jump to next file if no TEMP data
        continue

#    # subset data based on grid extremes
#    subset_ds = data_xr.where(
#    (data_xr.LONGITUDE >= min_lon) & (data_xr.LONGITUDE <= max_lon) &
#    (data_xr.LATITUDE >= min_lat) & (data_xr.LATITUDE <= max_lat),
#    drop=True
#    )

#    if subset_ds.TEMP.size == 0: # If no TEMP data in our model region
#        continue
    elif ((float(data_xr.geospatial_lon_min) >= min_lon) & (float(data_xr.geospatial_lon_max) <= max_lon) &
         (float(data_xr.geospatial_lat_min) >= min_lat) & (float(data_xr.geospatial_lat_max) <= max_lat)):
        count = count + 1
        # create the NETCDF files
        data_xr.to_netcdf(os.getenv("CYLC_SUITE_WORK_DIR") + '/../output/obs/' + 'INSITU_TS_' + year + month + day + '_' + str(count)+ '.nc') #outfile)
    
    del data_xr # To amke sure it doesn't contaminate the following file