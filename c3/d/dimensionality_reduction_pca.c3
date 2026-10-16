module dimensionality_reduction_pca;
extern fn double atan2(double y,double x);
extern fn double cos(double x);
extern fn double sin(double x);
fn long dimensionality_reduction_pca(double* v,usz n,double* out,usz cap) @export("dimensionality_reduction_pca") {
 if(v==null||n<7||v[0]!=2.0||v[2]!=1.0||v[1]<2.0||v[1]>8.0||v[1]!=(double)(long)v[1])return -1;
 usz m=(usz)v[1];if(n!=3+2*m)return -1;double[8] x;double[8] y;double mx=0.0;double my=0.0;
 for(usz i=0;i<m;i++){x[i]=v[3+i];y[i]=v[3+m+i];if(x[i]!=x[i]||y[i]!=y[i]||x[i]<-1e6||x[i]>1e6||y[i]<-1e6||y[i]>1e6)return -1;mx+=x[i];my+=y[i];}mx/=m;my/=m;double a=0.0;double b=0.0;double d=0.0;
 for(usz i=0;i<m;i++){double dx=x[i]-mx;double dy=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy;}a/=m;b/=m;d/=m;if(b<=0.0||((a-d)<0?d-a:a-d)+b==0.0)return -1;
 double t=0.5*atan2(2.0*b,a-d);double vx=cos(t);double vy=sin(t);if(out==null||cap<m)return -2;for(usz i=0;i<m;i++)out[i]=vx*x[i]+vy*y[i];return (long)m;
}
