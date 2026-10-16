module pyramid;
extern fn double pow(double x,double y);
extern fn double sqrt(double x);
fn double pyramid(long* v, ulong n) @export("pyramid"){if(v==null||n!=3||v[0]<0||v[0]>1||v[1]<1||v[1]>10000000||v[2]<1||v[2]>10000000)return -1e300;double b=(double)v[1]/1000.0,h=(double)v[2]/1000.0,area=pow(b,2.0);if(v[0]==0)return (area*h)/3.0;return area+((b*4.0)/2.0)*sqrt(pow(b/2.0,2.0)+pow(h,2.0));}
