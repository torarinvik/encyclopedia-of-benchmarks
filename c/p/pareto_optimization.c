#include <stddef.h>
#include <stdint.h>
#define MAX_ROWS 64
#define MAX_COLS 8
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t feed(uint64_t h,int64_t v){uint64_t b=(uint64_t)v;for(unsigned s=0;s<64;s+=8)h=(h^(uint8_t)(b>>s))*FNV_PRIME;return h;}
int64_t pareto_optimization(const int64_t *a,size_t len){
 if(a==NULL||len<2||len>514)return -1;int64_t r64=a[0],c64=a[1];
 if(r64<1||r64>64||c64<1||c64>8||len!=2+(size_t)(r64*c64))return -1;
 size_t r=(size_t)r64,c=(size_t)c64;for(size_t k=0;k<r*c;k++)if(a[2+k]<-1000||a[2+k]>1000)return -1;
 uint8_t keep[64];int64_t kept=0;
 for(size_t i=0;i<r;i++){keep[i]=1;for(size_t j=0;j<r;j++){if(i==j)continue;int ge=1,gt=0;for(size_t x=0;x<c;x++){int64_t l=a[2+j*c+x],v=a[2+i*c+x];if(l<v)ge=0;if(l>v)gt=1;}if(ge&&(gt||j<i)){keep[i]=0;break;}}if(keep[i])kept++;}
 uint64_t h=feed(FNV_OFFSET,kept);h=feed(h,c64);for(size_t i=0;i<r;i++)if(keep[i])for(size_t x=0;x<c;x++)h=feed(h,a[2+i*c+x]);return (int64_t)(h&UINT64_C(0x7fffffffffffffff));
}
