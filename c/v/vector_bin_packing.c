/* Clean-room generalized vector First Fit bin-packing profile. */
#include <stddef.h>
#include <stdint.h>
enum{MAX_N=32,MAX_D=4,MAX_INPUT=130,MAX_FIELDS=161};
static void put(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)(b&255u);b>>=8;}}
int64_t vector_bin_packing(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<2||length>MAX_INPUT)return -1;int64_t n64=input[0],d64=input[1];if(n64<1||n64>32||d64<1||d64>4||length!=2+(size_t)(n64*d64))return -1;size_t n=(size_t)n64,d=(size_t)d64;for(size_t i=0;i<n*d;++i)if(input[2+i]<0||input[2+i]>1000)return -1;
 int64_t load[MAX_N][MAX_D]={{0}};size_t assignment[MAX_N]={0},bins=0;for(size_t item=0;item<n;++item){size_t chosen=bins;for(size_t b=0;b<bins;++b){int fits=1;for(size_t q=0;q<d;++q)if(load[b][q]+input[2+item*d+q]>1000)fits=0;if(fits){chosen=b;break;}}if(chosen==bins)++bins;assignment[item]=chosen;for(size_t q=0;q<d;++q)load[chosen][q]+=input[2+item*d+q];}
 int64_t staged[MAX_FIELDS]={0};size_t count=0;staged[count++]=(int64_t)bins;for(size_t i=0;i<n;++i)staged[count++]=(int64_t)assignment[i];for(size_t b=0;b<bins;++b)for(size_t q=0;q<d;++q)staged[count++]=load[b][q];if(!output||capacity<8*count)return -2;for(size_t i=0;i<count;++i)put(output,8*i,staged[i]);return (int64_t)(8*count);
}
