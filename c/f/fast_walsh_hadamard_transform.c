#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 128
#define MAX_ABS_VALUE 10000
int64_t fast_walsh_hadamard_transform(const int64_t *v,size_t len,uint8_t *out,size_t cap){
 if(!v||len<2||len>MAX_LENGTH+2|| (v[0]!=0&&v[0]!=1)||v[1]<1||v[1]>MAX_LENGTH) return -1;
 size_t n=(size_t)v[1]; if((n&(n-1))||len!=n+2) return -1;
 int64_t a[MAX_LENGTH]; for(size_t i=0;i<n;i++){if(v[i+2]<-MAX_ABS_VALUE||v[i+2]>MAX_ABS_VALUE)return -1;a[i]=v[i+2];}
 for(size_t h=1;h<n;h*=2) for(size_t b=0;b<n;b+=2*h) for(size_t j=0;j<h;j++){int64_t x=a[b+j],y=a[b+j+h];a[b+j]=x+y;a[b+j+h]=x-y;}
 if(v[0]) for(size_t i=0;i<n;i++){if(a[i]%(int64_t)n)return -1;a[i]/=(int64_t)n;}
 if(n*8>cap||!out)return -2;
 for(size_t i=0;i<n;i++){uint64_t x=(uint64_t)a[i];for(size_t k=0;k<8;k++)out[i*8+k]=(uint8_t)(x>>(8*k));} return (int64_t)n;
}
