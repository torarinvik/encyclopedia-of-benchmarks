module geofence;
const double PI = 3.14159265358979323846264338327950288;
extern fn double sin(double x); extern fn double cos(double x); extern fn double sqrt(double x); extern fn double atan2(double y,double x);
fn long geofence(long* a,usz n) @export("geofence") {
 if(a==null||n!=5)return -1;
 if(a[0]<-90000000||a[0]>90000000||a[2]<-90000000||a[2]>90000000||a[1]<-180000000||a[1]>180000000||a[3]<-180000000||a[3]>180000000||a[4]<-1000000||a[4]>30000000000)return -1;
 double f=PI/180000000.0;double lat1=(double)a[0]*f;double lon1=(double)a[1]*f;double lat2=(double)a[2]*f;double lon2=(double)a[3]*f;
 double dl=lat2-lat1;double dg=lon2-lon1;double s1=sin(dl/2.0);double s2=sin(dg/2.0);double hav=s1*s1+cos(lat1)*cos(lat2)*s2*s2;
 if(hav<0.0)hav=0.0;if(hav>1.0)hav=1.0;double dist=6371010.0*(2.0*atan2(sqrt(hav),sqrt(1.0-hav)));
 return (long)(dist<=(double)a[4]/1000.0);
}
