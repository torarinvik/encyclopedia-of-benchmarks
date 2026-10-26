/* Clean-room exact bounded minimum weighted connected dominating set. */
#include <stddef.h>
#include <stdint.h>
enum{MAX_N=16};
static void put(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)b;b>>=8;}}
int64_t weighted_connected_dominating_set(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<3||n>33||v[0]<1||v[0]>MAX_N)return -1;size_t count=(size_t)v[0];if(n!=1+2*count)return -1;uint64_t all=(UINT64_C(1)<<count)-1,adj[MAX_N]={0};
 for(size_t i=0;i<count;++i){int64_t mask=v[1+i],weight=v[1+count+i];if(mask<0||(uint64_t)mask>all||((uint64_t)mask&(UINT64_C(1)<<i))||weight<1||weight>1000)return -1;adj[i]=(uint64_t)mask;}for(size_t i=0;i<count;++i)for(size_t j=0;j<count;++j)if(((adj[i]>>j)&1u)!=((adj[j]>>i)&1u))return -1;
 int64_t best_cost=-1;uint64_t best_mask=0;for(uint64_t mask=1;mask<=all;++mask){uint64_t dominated=mask;int64_t cost=0;for(size_t i=0;i<count;++i)if((mask>>i)&1u){dominated|=adj[i];cost+=v[1+count+i];}if(dominated!=all)continue;uint64_t seen=mask&(~mask+1),old;do{old=seen;for(size_t i=0;i<count;++i)if((seen>>i)&1u)seen|=adj[i]&mask;}while(seen!=old);if(seen!=mask)continue;if(best_cost<0||cost<best_cost||(cost==best_cost&&mask<best_mask)){best_cost=cost;best_mask=mask;}}
 if(!out||cap<16)return -2;put(out,0,best_cost);put(out,8,(int64_t)best_mask);return 16;
}
