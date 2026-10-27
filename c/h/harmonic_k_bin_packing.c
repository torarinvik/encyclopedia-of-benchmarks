#include <stddef.h>
#include <stdint.h>
#define MAX_N 32
#define MAX_K 8
#define MAX_INPUT 34
#define CAPACITY 10000
static void store_i64_le(uint8_t *out,size_t off,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[off+b]=(uint8_t)(bits&255U);bits>>=8;}}
int64_t harmonic_k_bin_packing(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(input==NULL||length<3||length>MAX_INPUT)return -1;
 int64_t k64=input[0],n64=input[1];
 if(k64<3||k64>MAX_K||n64<1||n64>MAX_N||length!=(size_t)(2+n64))return -1;
 size_t k=(size_t)k64,n=(size_t)n64;
 for(size_t i=0;i<n;++i)if(input[2+i]<1||input[2+i]>CAPACITY)return -1;
 size_t bytes=8*(n+1);if(output==NULL||capacity<bytes)return -2;
 int64_t current[MAX_K],remaining[MAX_K]={0},assignment[MAX_N];
 for(size_t c=0;c<MAX_K;++c)current[c]=-1;
 int64_t bins=0;
 for(size_t i=0;i<n;++i){int64_t size=input[2+i];size_t kind=k-1;
  for(size_t c=0;c<k-1;++c)if(size*(int64_t)(c+2)>CAPACITY){kind=c;break;}
  if(current[kind]<0||size>remaining[kind]){current[kind]=bins++;remaining[kind]=CAPACITY;}
  assignment[i]=current[kind];remaining[kind]-=size;
 }
 store_i64_le(output,0,bins);for(size_t i=0;i<n;++i)store_i64_le(output,8*(i+1),assignment[i]);return (int64_t)bytes;
}
