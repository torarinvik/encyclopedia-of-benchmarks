#include <stddef.h>
#include <stdint.h>
#define MAX_N 32
#define MAX_INPUT 35
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
int64_t max_average_length_bounded_segment(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<4||len>MAX_INPUT)return -1;int64_t n64=in[0],l64=in[1],u64=in[2];if(n64<1||n64>MAX_N||l64<1||u64<l64||u64>n64||len!=(size_t)(3+n64))return -1;size_t n=(size_t)n64,l=(size_t)l64,u=(size_t)u64;
 for(size_t i=0;i<n;++i)if(in[3+i]<-10000||in[3+i]>10000)return -1; if(!out||cap<32)return -2;
 int64_t bs=0,bl=1,bstart=0,bend=0;int have=0;
 for(size_t start=0;start<n;++start){int64_t sum=0;size_t limit=start+u<n?start+u:n;for(size_t end=start+1;end<=limit;++end){sum+=in[3+end-1];size_t length=end-start;if(length<l)continue;int64_t left=sum*bl,right=bs*(int64_t)length;
  if(!have||left>right||(left==right&&(length<(size_t)bl||(length==(size_t)bl&&(start<(size_t)bstart||(start==(size_t)bstart&&end<(size_t)bend)))))){bs=sum;bl=(int64_t)length;bstart=(int64_t)start;bend=(int64_t)end;have=1;}
 }}put64(out,0,bs);put64(out,8,bl);put64(out,16,bstart);put64(out,24,bend);return 32;
}
