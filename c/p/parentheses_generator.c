#include <stddef.h>
#include <stdint.h>
static const int counts[7]={1,1,2,5,14,42,132};
static void gen(int n,int open,int close,uint8_t* path,uint8_t* out,int* index){if(open+close==2*n){for(int i=0;i<2*n;i++)out[2+(*index)*(2*n)+i]=path[i];(*index)++;return;}if(open<n){path[open+close]='(';gen(n,open+1,close,path,out,index);}if(close<open){path[open+close]=')';gen(n,open,close+1,path,out,index);}}
int64_t parentheses_generator(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=1||v[0]<0||v[0]>6)return -1;int pairs=(int)v[0],needed=2+counts[pairs]*2*pairs;if(needed>cap||!out)return -2;out[0]=(uint8_t)counts[pairs];out[1]=(uint8_t)(counts[pairs]>>8);int index=0;uint8_t path[12];gen(pairs,0,0,path,out,&index);return needed;}
