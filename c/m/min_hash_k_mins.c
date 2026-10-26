#include <stddef.h>
#include <stdint.h>
#define N 16
#define K 4
#define L 66
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
int64_t min_hash_k_mins(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<3||len>L)return -1;int64_t nr=in[0],kr=in[1];if(nr<1||nr>N||kr<1||kr>K||len!=2+(size_t)nr*(size_t)kr)return -1;size_t n=(size_t)nr,k=(size_t)kr;for(size_t i=0;i<n*k;i++)if(in[2+i]<0||in[2+i]>1000)return -1;size_t bytes=8*k;if(!out||cap<bytes)return -2;for(size_t col=0;col<k;col++){size_t best=0;for(size_t row=1;row<n;row++)if(in[2+row*k+col]<in[2+best*k+col])best=row;put64(out,8*col,(int64_t)best);}return (int64_t)bytes;}
