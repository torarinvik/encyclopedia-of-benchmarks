/* Return page-reference hit/eviction events and the final MRU-to-LRU cache. */
#include <stddef.h>
#include <stdint.h>
int64_t lru_page_reference(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<2)return -1;int64_t c64=in[0],n64=in[1];if(c64<1||c64>64||(c64&(c64-1))||n64<0||n64>256||len!=(size_t)n64+2)return -1;
 size_t c=(size_t)c64,n=(size_t)n64;for(size_t i=0;i<n;i++)if(in[2+i]<0||in[2+i]>1000000)return -1;
 int64_t cache[64],events[512];size_t used=0;
 for(size_t i=0;i<n;i++){int64_t page=in[2+i],evicted=-1;size_t p=0;while(p<used&&cache[p]!=page)p++;
  if(p<used){for(size_t j=p;j>0;j--)cache[j]=cache[j-1];cache[0]=page;events[2*i]=1;}
  else{if(used==c){evicted=cache[used-1];--used;}for(size_t j=used;j>0;j--)cache[j]=cache[j-1];cache[0]=page;++used;events[2*i]=0;}events[2*i+1]=evicted;
 }
 size_t words=2*n+2+used;if(!out||cap<words*8)return -2;
 int64_t result[2*256+66];size_t k=0;result[k++]=(int64_t)n;for(size_t i=0;i<2*n;i++)result[k++]=events[i];result[k++]=(int64_t)used;for(size_t i=0;i<used;i++)result[k++]=cache[i];
 for(size_t i=0;i<k;i++){uint64_t bits=(uint64_t)result[i];for(size_t b=0;b<8;b++)out[i*8+b]=(uint8_t)(bits>>(8*b));}return (int64_t)(words*8);
}
