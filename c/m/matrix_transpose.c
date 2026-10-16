#include <stddef.h>
#include <stdint.h>
#define MAX_CELLS 1024
static void store_le(uint8_t *out,size_t off,int64_t value){uint64_t u=(uint64_t)value;for(size_t b=0;b<8;b++)out[off+b]=(uint8_t)(u>>(8*b));}
int64_t matrix_transpose(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<2||n>1027)return -1;int64_t r=v[0],c=v[1];if(r<1||r>32||c<1||c>32||n!=2+(size_t)r*(size_t)c)return -1;
 int64_t matrix[MAX_CELLS],result[MAX_CELLS];size_t rows=(size_t)r,cols=(size_t)c;for(size_t i=0;i<rows*cols;i++){if(v[2+i]<-2147483648LL||v[2+i]>2147483647LL)return -1;matrix[i]=v[2+i];}
 size_t orows=cols,ocols=rows;
 for(size_t i=0;i<rows;i++)for(size_t j=0;j<cols;j++){size_t rr,cc;rr=j;cc=i;result[rr*ocols+cc]=matrix[i*cols+j];}
 size_t bytes=8*(2+orows*ocols);if(!out||cap<bytes)return -2;store_le(out,0,(int64_t)orows);store_le(out,8,(int64_t)ocols);for(size_t i=0;i<orows*ocols;i++)store_le(out,16+8*i,result[i]);return (int64_t)bytes;
}
