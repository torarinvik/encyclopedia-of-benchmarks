#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*out,size_t pos,int64_t x){uint64_t u=(uint64_t)x;for(int i=0;i<8;i++)out[pos+i]=(uint8_t)(u>>(8*i));}
static void emit_gen(const int64_t*v,size_t n,size_t i,int64_t*sel,size_t used,uint8_t*out,size_t*cursor){if(i==n){out[(*cursor)++]=(uint8_t)used;for(size_t j=0;j<used;j++){put64(out,*cursor,sel[j]);*cursor+=8;}return;}emit_gen(v,n,i+1,sel,used,out,cursor);sel[used]=v[i];emit_gen(v,n,i+1,sel,used+1,out,cursor);}
int64_t powerset(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<1||n>7||v[0]<0||v[0]>6||n!=(size_t)v[0]+1)return -1;size_t count=(size_t)v[0],subsets=(size_t)1<<count,need=2+subsets+8*count*(subsets/2);for(size_t i=1;i<n;i++)if(v[i]<-1000000||v[i]>1000000)return -1;if(need>cap||!out)return -2;out[0]=(uint8_t)subsets;out[1]=(uint8_t)(subsets>>8);int64_t selected[6];size_t cursor=2;emit_gen(v+1,count,0,selected,0,out,&cursor);return (int64_t)need;}
