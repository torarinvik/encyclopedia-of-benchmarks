#include <stddef.h>
#include <stdint.h>
int64_t one_hot_encode(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<2||n>33||v[0]<1||v[0]>32||n!=(size_t)v[0]+1)return -1;size_t rows=(size_t)v[0];uint8_t present[26]={0};
 for(size_t i=0;i<rows;i++){if(v[i+1]<0||v[i+1]>25)return -1;present[v[i+1]]=1;}
 size_t cols=0;for(size_t i=0;i<26;i++)if(present[i])cols++;size_t need=rows*cols;if(need>cap||(need&&!out))return -2;
 size_t col=0;size_t map[26];for(size_t i=0;i<26;i++)if(present[i])map[i]=col++;
 for(size_t r=0;r<rows;r++)for(size_t c=0;c<cols;c++)out[r*cols+c]=(uint8_t)(map[v[r+1]]==c);
 return (int64_t)need;
}
