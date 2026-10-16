#include <stddef.h>
#include <stdint.h>
#define MAX_N 8
#define MAX_OUTPUT_WORDS 737
static int safe(const int *rows,int col,int row){for(int c=0;c<col;++c){int prior=rows[c];if(prior==row||prior-c==row-col||prior+c==row+col)return 0;}return 1;}
static void enumerate(int n,int col,int *rows,int64_t *out,size_t *used){if(col==n){for(int c=0;c<n;++c)out[(*used)++]=rows[c];out[0]+=1;return;}for(int row=0;row<n;++row)if(safe(rows,col,row)){rows[col]=row;enumerate(n,col+1,rows,out,used);}}
static void put_i64(uint8_t*out,size_t index,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[index*8+b]=(uint8_t)(bits>>(8*b));}
int64_t n_queens_backtracking_csharp(int64_t n,uint8_t*output,size_t capacity){if(n<0||n>MAX_N)return -1;int64_t values[MAX_OUTPUT_WORDS]={0};size_t used=1;if(n>0){int rows[MAX_N]={0};enumerate((int)n,0,rows,values,&used);}size_t required=used*8;if(output==NULL||capacity<required)return -2;for(size_t i=0;i<used;++i)put_i64(output,i,values[i]);return (int64_t)required;}
