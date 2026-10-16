#include <stddef.h>
#include <stdint.h>
static int64_t rnd(double x){double z=x*1000.0;return z>=0?(int64_t)(z+0.5):-(int64_t)(-z+0.5);}
int64_t liang_barsky(const int64_t*v,size_t n){if(n!=8)return -1;for(int i=0;i<8;i++)if(v[i]<-5||v[i]>5)return -1;double xmin=v[0],ymin=v[1],xmax=v[2],ymax=v[3],x0=v[4],y0=v[5],x1=v[6],y1=v[7];if(xmin>=xmax||ymin>=ymax)return -1;double dx=x1-x0,dy=y1-y0,p[4]={-dx,dx,-dy,dy},q[4]={x0-xmin,xmax-x0,y0-ymin,ymax-y0},t0=0,t1=1;for(int i=0;i<4;i++){double t=q[i]/p[i];if(p[i]==0&&q[i]<0)return -1;else if(p[i]<0){if(t>t1)return -1;if(t>t0)t0=t;}else if(p[i]>0){if(t<t0)return -1;if(t<t1)t1=t;}}double z[4]={x0+t0*dx,y0+t0*dy,x0+t1*dx,y0+t1*dy};int64_t r=0;for(int i=0;i<4;i++)r=r*10001+rnd(z[i])+5000;return r;}
