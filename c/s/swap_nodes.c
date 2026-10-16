#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*out,size_t*p,int64_t x){uint64_t v=(uint64_t)x;for(size_t j=0;j<8;j++){out[(*p)++]=(uint8_t)v;v>>=8;}}
int64_t swap_nodes(const int64_t*input,size_t length,uint8_t*output,size_t capacity){if(input==NULL||length<3)return -1;int64_t nn=input[0];if(nn<0||nn>64||length!=(size_t)nn+3)return -1;size_t n=(size_t)nn;for(size_t i=0;i<n;i++)if(input[1+i]<INT32_MIN||input[1+i]>INT32_MAX)return -1;int64_t a=input[1+n],b=input[2+n];if(a<INT32_MIN||a>INT32_MAX||b<INT32_MIN||b>INT32_MAX)return -1;size_t need=8+8*n;if(output==NULL||capacity<need)return -2;size_t ia=n,ib=n;if(a!=b){for(size_t i=0;i<n;i++){if(ia==n&&input[1+i]==a)ia=i;if(ib==n&&input[1+i]==b)ib=i;}}
 size_t pos=0;put64(output,&pos,nn);for(size_t i=0;i<n;i++){int64_t x=input[1+i];if(a!=b&&ia<n&&ib<n){if(i==ia)x=b;else if(i==ib)x=a;}put64(output,&pos,x);}return (int64_t)pos;}
