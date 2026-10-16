#include <stdint.h>
#include <stddef.h>
#define MAX_SAMPLES 32
static const int64_t A[11]={1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500};
static const int64_t B[11]={60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672};
static const int64_t HA[3]={1089966811,-2146993250,1057516837};
static const int64_t HB[3]={1073619225,-2147238449,1073619225};

static int64_t step(int64_t sample,const int64_t*a,const int64_t*b,int order,int64_t*x,int64_t*y){int64_t acc=b[0]*sample;for(int i=1;i<=order;i++)acc+=b[i]*x[i-1]-a[i]*y[i-1];int64_t out=acc/a[0];for(int i=order-1;i>0;i--){x[i]=x[i-1];y[i]=y[i-1];}if(order){x[0]=sample;y[0]=out;}return out;}
int64_t equal_loudness_filter(const int64_t*v,size_t n){if(!v||n<1||n>MAX_SAMPLES+1)return -1;int64_t count=v[0];if(count<0||count>MAX_SAMPLES||n!=(size_t)count+1)return -1;int64_t x[10]={0},y[10]={0},hx[2]={0},hy[2]={0},out=0;for(int64_t i=0;i<count;i++){if(v[i+1]<-1000000||v[i+1]>1000000)return -1;int64_t mid=step(v[i+1],A,B,10,x,y);out=step(mid,HA,HB,2,hx,hy);}return out;}
