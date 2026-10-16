import std/math
proc geofence*(a:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"geofence".} =
 if a==nil or n!=5:return -1
 if a[0]< -90000000 or a[0]>90000000 or a[2]< -90000000 or a[2]>90000000 or a[1]< -180000000 or a[1]>180000000 or a[3]< -180000000 or a[3]>180000000 or a[4]< -1000000 or a[4]>30000000000:return -1
 let factor=PI/180000000.0
 let lat1=float64(a[0])*factor;let lon1=float64(a[1])*factor;let lat2=float64(a[2])*factor;let lon2=float64(a[3])*factor
 let dlat=lat2-lat1;let dlon=lon2-lon1;let s1=sin(dlat/2);let s2=sin(dlon/2)
 var hav=s1*s1+cos(lat1)*cos(lat2)*s2*s2
 if hav<0: hav=0
 if hav>1: hav=1
 let distance=6371010.0*(2*arctan2(sqrt(hav),sqrt(1-hav)))
 int64(distance<=float64(a[4])/1000.0)
