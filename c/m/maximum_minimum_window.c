#include <stddef.h>
#include <stdint.h>
#define NMAX 256
static void store(int64_t x,uint8_t *o,size_t p){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;b++)o[p+b]=(uint8_t)(u>>(8*b));}
int64_t maximum_minimum_window(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length<2)return -2; int64_t n0=input[0]; if(n0<1||n0>NMAX||length!=(size_t)n0+1)return -2; size_t n=(size_t)n0;
 for(size_t i=0;i<n;i++)if(input[i+1]<0||input[i+1]>1000000)return -2;
 if(!output||capacity<n*8)return -3;
 size_t stack[NMAX],top=0; int left[NMAX],right[NMAX]; int64_t ans[NMAX+1]={0};
 for(size_t i=0;i<n;i++){while(top&&input[stack[top-1]+1]>=input[i+1])top--;left[i]=top?(int)stack[top-1]:-1;stack[top++]=i;}
 top=0; for(size_t ii=n;ii>0;ii--){size_t i=ii-1;while(top&&input[stack[top-1]+1]>=input[i+1])top--;right[i]=top?(int)stack[top-1]:(int)n;stack[top++]=i;}
 for(size_t i=0;i<n;i++){size_t len=(size_t)(right[i]-left[i]-1);if(input[i+1]>ans[len])ans[len]=input[i+1];}
 for(size_t i=n;i>1;i--)if(ans[i-1]<ans[i])ans[i-1]=ans[i];
 for(size_t i=1;i<=n;i++)store(ans[i],output,(i-1)*8); return (int64_t)n;
}
