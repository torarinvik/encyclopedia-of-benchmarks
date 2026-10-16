#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT 4096
int64_t prefix_function(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<1||n>MAX_TEXT+1||v[0]<0||v[0]>MAX_TEXT||n!=(size_t)v[0]+1)return -1;size_t len=(size_t)v[0];for(size_t i=0;i<len;i++)if(v[i+1]<0||v[i+1]>127)return -1;size_t bytes=4*len;if(bytes>cap||(bytes&&!out))return -2;uint32_t pi[MAX_TEXT]={0};for(size_t i=1;i<len;i++){size_t j=pi[i-1];while(j>0&&v[i+1]!=v[j+1])j=pi[j-1];if(v[i+1]==v[j+1])j++;pi[i]=(uint32_t)j;}for(size_t i=0;i<len;i++){uint32_t x=pi[i];out[4*i]=(uint8_t)x;out[4*i+1]=(uint8_t)(x>>8);out[4*i+2]=(uint8_t)(x>>16);out[4*i+3]=(uint8_t)(x>>24);}return (int64_t)bytes;}
