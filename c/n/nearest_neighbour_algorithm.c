#include <stddef.h>
#include <stdint.h>
int64_t nearest_neighbour_algorithm(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<2||n>257||v[0]<1||v[0]>16)return -1;size_t m=(size_t)v[0];if(n!=1+m*m)return -1;
 for(size_t i=1;i<n;i++)if(v[i]<0||v[i]>1000000)return -1;
 size_t path[16];uint8_t seen[16]={0};size_t current=0;
 for(size_t step=0;step<m;step++){path[step]=current;seen[current]=1;if(step+1==m)break;size_t best=m;int64_t distance=0;for(size_t j=0;j<m;j++)if(!seen[j]){int64_t d=v[1+current*m+j];if(best==m||d<distance){best=j;distance=d;}}current=best;}
 uint8_t bytes[64];size_t used=0;for(size_t i=0;i<m;i++){if(i)bytes[used++]=',';size_t x=path[i];if(x>=10)bytes[used++]=(uint8_t)('0'+x/10);bytes[used++]=(uint8_t)('0'+x%10);}
 if(used>cap||(used&&!out))return -2;for(size_t i=0;i<used;i++)out[i]=bytes[i];return (int64_t)used;
}
