#include <stddef.h>
#include <stdint.h>
#define MAX_NODES 5
static void put(uint8_t *o,size_t w,int64_t x){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;++b)o[w*8+b]=(uint8_t)(u>>(8*b));}
int64_t versabench_dbms_contract_root(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(v==NULL||n<3||n>12)return -1;int64_t nv=v[0];if(nv<1||nv>MAX_NODES||n!=1+2*(size_t)nv)return -1;size_t count=(size_t)nv;int64_t level[MAX_NODES],entries[MAX_NODES];
 for(size_t i=0;i<count;++i){level[i]=v[1+2*i];entries[i]=v[2+2*i];if(level[i]<0||level[i]>4||entries[i]<0||entries[i]>4)return -1;if(i+1<count&&(level[i]==0||entries[i]!=1||level[i+1]!=level[i]-1))return -1;}
 if(level[count-1]>0&&entries[count-1]==1)return -1;if(level[count-1]>0&&entries[count-1]==0&&count!=1)return -1;
 size_t root=0,promotions=0;while(level[root]>0&&entries[root]==1){++root;++promotions;}int64_t final_level=level[root],final_count=entries[root];if(final_level>0&&final_count==0){final_level=0;final_count=0;}
 if(out==NULL||cap<24)return -2;put(out,0,(int64_t)promotions);put(out,1,final_level);put(out,2,final_count);return 24;
}
