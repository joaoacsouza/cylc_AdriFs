# This script generate sla files to be assimilated cutting data on a domain
# defined from .shp file [see * for instructions].
# The program:
# 1- control if longitude is in the correct range [-180,180] otherwise correct it. 
# 2 -controls to not generate files without data on your domain.
# [*] Using Google Earth draw your domain and save it on a kml file.
#     Convert it on .shp file. There are tool online.
#     Unzip the dir generated and use the.shp file.
#     The others files in the unzipped dir are necessary. Do not remove them.

# Author: Marco Stefanelli
# Contact: marco.stefanelli@cmcc.it
# Date: 22/09/2022, London

#REMEMBER to run -> unset PROJ_LIB
import geopandas as gpd
import mercator
import matplotlib.pyplot as plt
import xarray as xr
import rioxarray
from shapely.geometry import mapping
import pandas as pd
import numpy as np
import rasterio 
import shapefile as shp
import subprocess
import glob

# Unset PROJ_LIB to avoid ERROR 1: proj.db not fount
command = 'unset PROJ_LIB'
subprocess.run([command], shell=True)

# load shapefile with geopandas
sani = gpd.read_file('SANI_shp/SANI.shp')

# load nc file
### list_of_files = sorted(glob.glob('/data/inputs/metocean/historical/obs/satellite/altimetry/CLS/Jason-3/L3/day/2017/*/nrt_med_j3_sla_vfec*'))
### list_of_files = sorted(glob.glob('/data/inputs/metocean/historical/obs/satellite/altimetry/CLS/Jason-3/L3/day/2017/*/nrt_med_j3_phy_assim*'))

### NAMELIST ##################################

#list_of_files = sorted(glob.glob('SLA_ALTIKA/nrt_med_al_sla_vfec*'))      # variable is SLA
#list_of_files = sorted(glob.glob('SLA_ALTIKA/nrt_med_al_phy_assim*'))     # variable is sla_filtered

#list_of_files = sorted(glob.glob('SLA_CRYOSAT2/nrt_med_c2_sla_vfec*'))      # variable is SLA
list_of_files = sorted(glob.glob('SLA_CRYOSAT2/nrt_med_c2_phy_assim*'))     # variable is sla_filtered

#list_of_files = sorted(glob.glob('SLA_JASON3/nrt_med_j3_sla_vfec*'))      # variable is SLA
#list_of_files = sorted(glob.glob('SLA_JASON3/nrt_med_j3_phy_assim*'))     # variable is sla_filtered

#list_of_files = sorted(glob.glob('SLA_SENTINEL3A/nrt_med_s3a_sla_vfec*'))      # variable is SLA
#list_of_files = sorted(glob.glob('SLA_SENTINEL3A/nrt_med_s3a_phy_assim*'))     # variable is sla_filtered

#satellite='ALTIKA'
satellite='CRYOSAT2'
#satellite='JASON3'
#satellite='SENTINEL3A'

#var='SLA'
var='sla_filtered'

si=0 # The first run for each satelite name MUST be si=0. For naming file with the correct number: satellite+si --> JASON3001, JASON3002, etc..

debug=False
k=2 # Set to 1 if you need plot of first  file with wrong longitude before and after correction
i=0 # To count the number of files with data in the input domain
j=0 # To count the number of files with no data in the input domain
################################################
for file in list_of_files:
    if debug == True:
        if var == 'SLA':
            print(file[31:39])
        else:
            print(file[35:43])
        
    data_xr = xr.open_dataset(file)
    if data_xr.attrs['geospatial_lon_max'] > 180: 
            if debug == True:
                print("--> Lon range [0,360], max lon is:", "{:.2f}".format(data_xr.attrs['geospatial_lon_max']))
                print("--> Lon range is:[" + str("{:.2f}".format(np.min(data_xr['longitude'].values))) + "," + str("{:.2f}".format(np.max(data_xr['longitude'].values))) + "]")
                print("--> Convert in range [-180,180]")
            if k==1:
                fig = plt.figure(figsize=(8, 8))
                ax=plt.axes(projection='mercator')
                plt.gca().coastline('medsea_h.shp', sea=None, zorder=2)
                ax.scatter(x=data_xr.longitude, y=data_xr.latitude)
                plt.savefig('not_corrected.png')
                plt.show()
                plt.close(fig)

            encoding_lon_lat = data_xr.longitude.encoding
            encoding_sla = data_xr.sla_filtered.encoding
            with xr.set_options(keep_attrs=True):
               data_xr['longitude'] = (data_xr['longitude'] + 180) % 360 - 180
               data_xr.longitude.encoding.update(encoding_lon_lat, inplace=True)
               data_xr[var] = data_xr[var] + data_xr['ocean_tide']#*1000
               data_xr[var].encoding.update(encoding_sla, inplace=True)
               
            if debug == True:
                print("--> New lon range is:[" + str("{:.2f}".format(np.min(data_xr['longitude'].values))) + "," + str("{:.2f}".format(np.max(data_xr['longitude'].values))) + "]")
                print('*****************************') 
            if k==1:
                fig = plt.figure(figsize=(8, 8))
                ax=plt.axes(projection='mercator')
                plt.gca().coastline('medsea_h.shp', sea=None, zorder=2)
                ax.scatter(x=data_xr.longitude, y=data_xr.latitude)
                plt.savefig('corrected.png')
                plt.show()
                plt.close(fig)
                k=k+1

    #data = data.rio.write_crs("EPSG:4326", inplace=True)
    data = data_xr.to_dataframe()
    
    # the index in the df is a Pandas.MultiIndex. To reset it, use df.reset_index()
    data = data.reset_index()
    # use geopandas points_from_xy() to transform Longitude and Latitude into a list 
    # of shapely.Point objects and set it as a geometry while creating the GeoDataFrame
    data_gdf = gpd.GeoDataFrame(data, geometry=gpd.points_from_xy(data.longitude, data.latitude))
    
    # Clip points, lines, or polygon geometries to the mask extent.
    mask = gpd.clip(data_gdf, sani)
    #print(type(mask))
    mask=mask.set_index(['time'])
    ds=mask.drop(columns="geometry").to_xarray()
    ds=ds.set_coords(("latitude", "longitude"))
    if ds[var].size == 0:
        j=j+1  #Count number of files without data on tour domain
    else: 
        i=i+1  #Count number of files with data on tour domain
        si=si+1
        fill_value_sla = data_xr[var].encoding['_FillValue']
        scale_factor_sla = data_xr[var].encoding['scale_factor']
        scale_factor_lon = data_xr.longitude.encoding['scale_factor']
        scale_factor_lat = data_xr.latitude.encoding['scale_factor']
        time_units = data_xr.time.encoding['units']
        time_calendar = data_xr.time.encoding['calendar']

               
    
    # create the NETCDF files
        ds.to_netcdf('data_SLA_TIDE_2017/' + satellite + str(si).zfill(3), encoding={'time':{'units': time_units, 'calendar' : time_calendar},
                                       var:{'_FillValue' : fill_value_sla,'scale_factor' : scale_factor_sla}, 
                                       #var:{'scale_factor' : scale_factor_sla},
                                       'longitude':{'scale_factor' : scale_factor_lon },
                                       'latitude':{'scale_factor' : scale_factor_lat}})
print('************************************************************')                                       
print('--> files without track on your domain -->',j)
print('--> files with track on your domain    -->',i)
print('--> Total processed files              -->',i+j)
print('--> For the next files generation remember to set:  si=',si)
print('************************************************************')                                       
