#include <stddef.h>
#include <stdint.h>
static uint64_t feed(uint64_t h,int64_t x){uint64_t u=(uint64_t)x;for(int b=0;b<8;b++){h^=(uint8_t)(u>>(8*b));h*=UINT64_C(0x100000001b3);}return h;}
int64_t submatrix(const int64_t*v,size_t n){
 if(!v||n<6||n>70)return -1;int64_t rr=v[0],cc=v[1],rs=v[2],cs=v[3],nr=v[4],nc=v[5];if(rr<1||rr>8||cc<1||cc>8||rr*cc>64||n!=(size_t)(6+rr*cc))return -1;if(rs<0||rs>rr||cs<0||cs>cc||nr<0||nr>rr||nc<0||nc>cc||rs+nr>rr||cs+nc>cc)return -1;
 for(size_t i=6;i<n;i++)if(v[i]<-2147483648LL||v[i]>2147483647LL)return -1;uint64_t h=UINT64_C(0xcbf29ce484222325);h=feed(h,nr);h=feed(h,nc);for(int64_t r=0;r<nr;r++)for(int64_t c=0;c<nc;c++)h=feed(h,v[6+(size_t)(rs+r)*(size_t)cc+(size_t)(cs+c)]);return (int64_t)h;
}
