#include <stddef.h>
#include <stdint.h>
#define MAX_VALUES 512
static int winner(const int64_t *values,const int *tree,int left,int right){if(left<0)return right;if(right<0)return left;return values[left]<=values[right]?left:right;}
static void put_i64(uint8_t*out,size_t offset,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[offset+b]=(uint8_t)(bits>>(8*b));}
int64_t tournament_sort(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(input==NULL||length<1||input[0]<0||input[0]>MAX_VALUES)return -1;size_t n=(size_t)input[0];if(length!=1+n)return -1;
 int64_t values[MAX_VALUES];for(size_t i=0;i<n;++i){if(input[i+1]<INT32_MIN||input[i+1]>INT32_MAX)return -1;values[i]=input[i+1];}
 size_t leaves=1;while(leaves<n)leaves*=2;int tree[2*MAX_VALUES+1];for(size_t i=0;i<2*leaves;++i)tree[i]=-1;for(size_t i=0;i<n;++i)tree[leaves+i]=(int)i;for(size_t node=leaves;node-->1;)tree[node]=winner(values,tree,(int)(node*2),(int)(node*2+1));
 size_t bytes=(1+n)*8;if(output==NULL||capacity<bytes)return -2;put_i64(output,0,(int64_t)n);
 for(size_t out=0;out<n;++out){int w=tree[1];put_i64(output,(1+out)*8,values[w]);size_t node=leaves+(size_t)w;tree[node]=-1;while(node>1){node/=2;tree[node]=winner(values,tree,(int)(node*2),(int)(node*2+1));}}
 return (int64_t)bytes;
}
