#include <stddef.h>
#include <stdint.h>
#define QN 128
static uint32_t next_rng(uint32_t *s){uint32_t x=*s;x^=x<<13;x^=x>>17;x^=x<<5;*s=x?x:0x9e3779b9U;return *s;}
static size_t partition(int64_t*a,size_t lo,size_t hi){int64_t pivot=a[hi];size_t i=lo;for(size_t j=lo;j<hi;j++)if(a[j]<=pivot){int64_t t=a[i];a[i++]=a[j];a[j]=t;}int64_t t=a[i];a[i]=a[hi];a[hi]=t;return i;}
static int64_t select_k(int64_t*a,size_t lo,size_t hi,size_t k,uint32_t*state){if(lo==hi)return a[lo];size_t p=lo+(next_rng(state)%(uint32_t)(hi-lo+1));int64_t t=a[p];a[p]=a[hi];a[hi]=t;p=partition(a,lo,hi);size_t rank=p-lo+1;if(k==rank)return a[p];if(k<rank)return select_k(a,lo,p-1,k,state);return select_k(a,p+1,hi,k-rank,state);}
int64_t minimum_element_of_array(const int64_t*input,size_t length){if(!input||length<4)return -1;int64_t n0=input[0],k0=input[1],seed0=input[2];if(n0<1||n0>QN||length!=(size_t)n0+3||k0<1||k0>n0||seed0<0||seed0>2147483647)return -1;int64_t a[QN];for(size_t i=0;i<(size_t)n0;i++){a[i]=input[i+3];if(a[i]<-1000000||a[i]>1000000)return -1;for(size_t j=0;j<i;j++)if(a[i]==a[j])return -1;}uint32_t state=(uint32_t)seed0;if(!state)state=0x9e3779b9U;return select_k(a,0,(size_t)n0-1,(size_t)k0,&state);}
