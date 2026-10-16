#include <cstddef>
#include <cstdint>
#define MAX_CELLS 1024
static void store_le(std::uint8_t *out,std::size_t off,std::int64_t value){std::uint64_t u=(std::uint64_t)value;for(std::size_t b=0;b<8;b++)out[off+b]=(std::uint8_t)(u>>(8*b));}
extern "C" std::int64_t rotate_matrix_270(const std::int64_t *v,std::size_t n,std::uint8_t *out,std::size_t cap){
 if(!v||n<2||n>1027)return -1;std::int64_t r=v[0],c=v[1];if(r<1||r>32||c<1||c>32||n!=2+(std::size_t)r*(std::size_t)c)return -1;
 std::int64_t matrix[MAX_CELLS],result[MAX_CELLS];std::size_t rows=(std::size_t)r,cols=(std::size_t)c;for(std::size_t i=0;i<rows*cols;i++)matrix[i]=v[2+i];
 std::size_t orows=cols,ocols=rows;
 for(std::size_t i=0;i<rows;i++)for(std::size_t j=0;j<cols;j++){std::size_t rr,cc;rr=j;cc=rows-1-i;result[rr*ocols+cc]=matrix[i*cols+j];}
 std::size_t bytes=8*(2+orows*ocols);if(!out||cap<bytes)return -2;store_le(out,0,(std::int64_t)orows);store_le(out,8,(std::int64_t)ocols);for(std::size_t i=0;i<orows*ocols;i++)store_le(out,16+8*i,result[i]);return (std::int64_t)bytes;
}
