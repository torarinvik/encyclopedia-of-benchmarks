#include <stddef.h>
#include <stdint.h>

#define SC_N 8
#define SC_D 3
static void put64(uint8_t *p, int64_t x) { uint64_t u=(uint64_t)x; for(int b=0;b<8;b++) p[b]=(uint8_t)(u>>(8*b)); }
int64_t rodinia_streamcluster_pgain(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if(!v || n<5 || n>53) return -1;
    int64_t pn=v[0], dd=v[1], xx=v[2], z=v[3], mask=v[4];
    if(pn<2||pn>SC_N||dd<1||dd>SC_D||n!=5+(size_t)pn*(3+(size_t)dd)||xx<0||xx>=pn||z<1||z>64||mask<=0||(uint64_t)mask >= (UINT64_C(1)<<pn)||(mask&(INT64_C(1)<<xx))) return -1;
    int p=(int)pn,d=(int)dd,x=(int)xx; size_t q=5;
    int a[SC_N],w[SC_N],c[SC_N],coord[SC_N][SC_D]={{0}};
    for(int i=0;i<p;i++) { if(v[q]<0||v[q]>=p) return -1; a[i]=(int)v[q++]; if(!(mask&(INT64_C(1)<<a[i]))) return -1; }
    for(int i=0;i<p;i++) { if(v[q]<1||v[q]>4) return -1; w[i]=(int)v[q++]; }
    for(int i=0;i<p;i++) c[i]=(int)v[q++];
    for(int i=0;i<p;i++) for(int k=0;k<d;k++) { if(v[q]<-8||v[q]>8) return -1; coord[i][k]=(int)v[q++]; }
    for(int i=0;i<p;i++) { int dist=0; for(int k=0;k<d;k++){int t=coord[i][k]-coord[a[i]][k];dist+=t*t;} if(c[i]!=w[i]*dist||((mask&(INT64_C(1)<<i))&&(a[i]!=i||c[i]!=0))) return -1; }
    int sw[SC_N]={0},low[SC_N]={0},close[SC_N]={0}; int64_t opening=z;
    for(int i=0;i<p;i++){int dist=0;for(int k=0;k<d;k++){int t=coord[i][k]-coord[x][k];dist+=t*t;}int xc=w[i]*dist;if(xc<c[i]){sw[i]=1;opening+=xc-c[i];}else low[a[i]]+=c[i]-xc;}
    for(int j=0;j<p;j++)if(mask&(INT64_C(1)<<j)){int64_t lo=z+low[j];if(lo>0){close[j]=1;opening-=lo;}}
    int opened=opening<0; int64_t gain=opened?-opening:0; int oa[SC_N],oc[SC_N];for(int i=0;i<p;i++){oa[i]=a[i];oc[i]=c[i];}
    int64_t om=mask;
    if(opened){for(int i=0;i<p;i++)if(sw[i]||close[a[i]]){int dist=0;for(int k=0;k<d;k++){int t=coord[i][k]-coord[x][k];dist+=t*t;}oa[i]=x;oc[i]=w[i]*dist;}for(int j=0;j<p;j++)if(close[j])om&=~(INT64_C(1)<<j);om|=INT64_C(1)<<x;}
    int64_t count=0,obj=0;for(int j=0;j<p;j++)if(om&(INT64_C(1)<<j))count++;obj=count*z;for(int i=0;i<p;i++)obj+=oc[i];
    if(!out||cap<(size_t)(8*(5+2*p)))return -2;
    int64_t r[21];r[0]=opened;r[1]=gain;r[2]=count;r[3]=om;r[4]=obj;for(int i=0;i<p;i++)r[5+i]=oa[i];for(int i=0;i<p;i++)r[5+p+i]=oc[i];for(int i=0;i<5+2*p;i++)put64(out+8*i,r[i]);return 5+2*p;
}
