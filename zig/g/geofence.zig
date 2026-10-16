const std=@import("std");
const PI_VALUE:f64=3.14159265358979323846264338327950288;
export fn geofence(a:[*c]const i64,n:usize)i64{
 if(a==null or n!=5)return -1;
 if(a[0]<-90000000 or a[0]>90000000 or a[2]<-90000000 or a[2]>90000000 or a[1]<-180000000 or a[1]>180000000 or a[3]<-180000000 or a[3]>180000000 or a[4]<-1000000 or a[4]>30000000000)return -1;
 const f=PI_VALUE/180000000.0;const lat1=@as(f64,@floatFromInt(a[0]))*f;const lon1=@as(f64,@floatFromInt(a[1]))*f;const lat2=@as(f64,@floatFromInt(a[2]))*f;const lon2=@as(f64,@floatFromInt(a[3]))*f;
 const dl=lat2-lat1;const dg=lon2-lon1;const s1=@sin(dl/2.0);const s2=@sin(dg/2.0);var h=s1*s1+@cos(lat1)*@cos(lat2)*s2*s2;if(h<0)h=0;if(h>1)h=1;
 const distance=6371010.0*(2.0*std.math.atan2(@sqrt(h),@sqrt(1-h)));
 return if(distance<=@as(f64,@floatFromInt(a[4]))/1000.0) 1 else 0;
}
