#create mass balance 2008

# Cut off mb in year 2008 from the collection aletsch_cmb_1865-2008.nc. Along the way (x,y) in m get lost.
cdo selyear,2008 aletsch_cmb_1865-2008.nc mb2008.nc

# therefore add (x,y) with ncks
ncks -A -v x,y aletsch_cmb_1865-2008.nc mb2008.nc