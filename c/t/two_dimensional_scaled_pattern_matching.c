/* Clean-room fixed-rational-scale geometric 2D pattern matching profile. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_INPUT=186, MAX_FIELDS=289, MAX_H=12, MAX_W=12 };
static void put_i64(uint8_t *out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)b;b>>=8;}}
int64_t two_dimensional_scaled_pattern_matching(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<6||n>MAX_INPUT)return -1;int64_t hh=v[0],ww=v[1],phh=v[2],pww=v[3],p=v[4],q=v[5];
 if(hh<1||hh>MAX_H||ww<1||ww>MAX_W||phh<1||phh>6||pww<1||pww>6||q<1||q>8||p<q||p>2*q)return -1;
 size_t h=(size_t)hh,w=(size_t)ww,ph=(size_t)phh,pw=(size_t)pww;if(n!=6+h*w+ph*pw)return -1;
 for(size_t i=0;i<h*w+ph*pw;++i)if(v[6+i]<0||v[6+i]>255)return -1;
 int64_t staged[MAX_FIELDS]={0};size_t count=1;
 for(size_t r=0;r<h;++r)for(size_t c=0;c<w;++c){if(p*(int64_t)ph>q*(int64_t)(h-r)||p*(int64_t)pw>q*(int64_t)(w-c))continue;int match=1;
  for(size_t y=0;y<h-r&&match;++y){if((2*(int64_t)y+1)*q>=2*p*(int64_t)ph)continue;size_t py=(size_t)(((2*(int64_t)y+1)*q)/(2*p));
   for(size_t x=0;x<w-c;++x){if((2*(int64_t)x+1)*q>=2*p*(int64_t)pw)continue;size_t px=(size_t)(((2*(int64_t)x+1)*q)/(2*p));if(v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]){match=0;break;}}
  }
  if(match){staged[count++]=(int64_t)r;staged[count++]=(int64_t)c;}
 }
 staged[0]=(int64_t)((count-1)/2);size_t bytes=8*count;if(!out||cap<bytes)return -2;for(size_t i=0;i<count;++i)put_i64(out,8*i,staged[i]);return (int64_t)bytes;
}
