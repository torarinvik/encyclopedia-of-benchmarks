/* Clean-room bounded k-partition MinHash update profile. */
#include <stddef.h>
#include <stdint.h>
#define MAX_K 8
#define MAX_N 32
#define MAX_RANK 1000
#define EMPTY_RANK 1001
static void put_i64(uint8_t *out,size_t pos,int64_t value){uint64_t b=(uint64_t)value;for(size_t i=0;i<8;i++)out[pos+i]=(uint8_t)(b>>(8*i));}
int64_t min_hash_k_partition(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length<2||length>66)return -1;int64_t k0=input[0],n0=input[1];
 if(k0<1||k0>MAX_K||n0<0||n0>MAX_N||length!=2+2*(size_t)n0)return -1;
 int k=(int)k0,n=(int)n0;int64_t best_id[MAX_K],best_rank[MAX_K];
 for(int b=0;b<k;b++){best_id[b]=-1;best_rank[b]=EMPTY_RANK;}
 for(int id=0;id<n;id++){int64_t bucket=input[2+2*id],rank=input[3+2*id];if(bucket<0||bucket>=k||rank<0||rank>MAX_RANK)return -1;
  if(best_id[bucket]<0||rank<best_rank[bucket]||(rank==best_rank[bucket]&&id<best_id[bucket])){best_id[bucket]=id;best_rank[bucket]=rank;}}
 int64_t staged[2*MAX_K];for(int b=0;b<k;b++){staged[2*b]=best_id[b];staged[2*b+1]=best_rank[b];}
 size_t required=(size_t)(2*k)*8;if(!output||capacity<required)return -2;for(size_t i=0;i<(size_t)(2*k);i++)put_i64(output,i*8,staged[i]);return (int64_t)required;
}
