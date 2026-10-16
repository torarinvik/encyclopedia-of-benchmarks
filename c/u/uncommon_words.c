#include <stddef.h>
#include <stdint.h>
#define MW 64
#define ML 16
int64_t uncommon_words(const int64_t *v,size_t n,uint8_t*out,size_t cap){if(!v||n<1||n>1089||v[0]<0||v[0]>MW)return -1;int lens[MW]={0},counts[MW]={0};uint8_t words[MW][ML]={{0}};int d=0;size_t p=1;for(int w=0;w<v[0];w++){if(p>=n||v[p]<1||v[p]>ML||v[p]>n-p-1)return -1;int l=(int)v[p++];for(int j=0;j<l;j++)if(v[p+j]<'a'||v[p+j]>'z')return -1;int id=0;for(;id<d;id++)if(lens[id]==l){int j=0;while(j<l&&words[id][j]==v[p+j])j++;if(j==l)break;}if(id==d){lens[d]=l;for(int j=0;j<l;j++)words[d][j]=(uint8_t)v[p+j];d++;}counts[id]++;p+=l;}if(p!=n)return -1;uint8_t temp[1089];size_t at=0;for(int id=0;id<d;id++)if(counts[id]==1){for(int j=0;j<lens[id];j++)temp[at++]=words[id][j];temp[at++]='\n';}if(at)at--;temp[at++]=0;if(!out||cap<at)return -2;for(size_t i=0;i<at;i++)out[i]=temp[i];return (int64_t)at;}
