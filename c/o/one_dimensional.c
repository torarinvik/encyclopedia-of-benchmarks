#include <stddef.h>
#include <stdint.h>
#define ROWS 17
#define WIDTH 31
#define OUTPUT_BYTES (ROWS*WIDTH*3)
int64_t one_dimensional(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n!=1||v[0]<0||v[0]>11111111)return -1;uint8_t digits[8]={0},rules[8]={0};uint64_t x=(uint64_t)v[0];size_t count=0;do{uint64_t d=x%10;if(d>1)return -1;digits[count++]=(uint8_t)d;x/=10;}while(x&&count<8);if(x)return -1;for(size_t i=0;i<count;i++)rules[8-count+i]=digits[count-1-i];
 uint8_t cells[ROWS][WIDTH]={0};cells[0][15]=1;
 for(size_t r=0;r+1<ROWS;r++)for(size_t c=0;c<WIDTH;c++){unsigned left=c?cells[r][c-1]:0,center=cells[r][c],right=c+1<WIDTH?cells[r][c+1]:0;unsigned pattern=(left<<2)|(center<<1)|right;cells[r+1][c]=rules[7-pattern];}
 if(cap<OUTPUT_BYTES||(OUTPUT_BYTES&&!out))return -2;size_t pos=0;for(size_t r=0;r<ROWS;r++)for(size_t c=0;c<WIDTH;c++){uint8_t color=cells[r][c]?0:255;out[pos++]=color;out[pos++]=color;out[pos++]=color;}return (int64_t)pos;
}
