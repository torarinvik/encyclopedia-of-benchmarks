#include <stddef.h>
#include <stdint.h>
#define MAX_N 16
#define MAX_K 8
#define MAX_INPUT 35
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
int64_t min_hash_bottom_k(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<4||len>MAX_INPUT)return -1;int64_t nr=in[0],kr=in[1];if(nr<1||nr>MAX_N||kr<1||kr>MAX_K||len!=2+2*(size_t)nr)return -1;size_t n=(size_t)nr,k=(size_t)kr;
 size_t ids[MAX_N],count=0;int64_t ranks[MAX_N];
 for(size_t i=0;i<n;i++){int64_t id=in[2+2*i],rank=in[3+2*i];if(id<0||id>=MAX_N||rank<0||rank>1000)return -1;for(size_t j=0;j<i;j++)if((size_t)id==ids[j])return -1;
  size_t pos=0;while(pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]<(size_t)id)))pos++;
  if(pos<k){size_t next=count<k?count:k-1;while(next>pos){ids[next]=ids[next-1];ranks[next]=ranks[next-1];next--;}ids[pos]=(size_t)id;ranks[pos]=rank;if(count<k)count++;}
 }
 size_t bytes=8*(1+2*count);if(!out||cap<bytes)return -2;put64(out,0,(int64_t)count);for(size_t i=0;i<count;i++){put64(out,8+16*i,(int64_t)ids[i]);put64(out,16+16*i,ranks[i]);}return (int64_t)bytes;
}
