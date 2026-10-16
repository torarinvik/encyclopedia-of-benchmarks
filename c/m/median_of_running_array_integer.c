#include <stddef.h>
#include <stdint.h>
#define LIM 256
typedef struct{int64_t v[LIM];size_t n;int max;}heap;
static void push(heap*h,int64_t x){size_t i=h->n++;h->v[i]=x;while(i){size_t p=(i-1)/2;int bad=h->max?h->v[p]<h->v[i]:h->v[p]>h->v[i];if(!bad)break;int64_t t=h->v[p];h->v[p]=h->v[i];h->v[i]=t;i=p;}}
static int64_t pop(heap*h){int64_t out=h->v[0];h->v[0]=h->v[--h->n];size_t i=0;for(;;){size_t l=2*i+1,r=l+1,b=i;if(l<h->n&&(h->max?h->v[l]>h->v[b]:h->v[l]<h->v[b]))b=l;if(r<h->n&&(h->max?h->v[r]>h->v[b]:h->v[r]<h->v[b]))b=r;if(b==i)break;int64_t t=h->v[i];h->v[i]=h->v[b];h->v[b]=t;i=b;}return out;}
static void store(int64_t x,uint8_t*out,size_t p){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;b++)out[p+b]=(uint8_t)(u>>(8*b));}
int64_t median_of_running_array_integer(const int64_t*input,size_t length,uint8_t*output,size_t cap){if(!input||length<2||input[0]<1||input[0]>LIM||length!=(size_t)input[0]+1)return -1;size_t n=(size_t)input[0];for(size_t i=0;i<n;i++)if(input[i+1]<-1000000||input[i+1]>1000000)return -1;if(!output||cap<n*8)return -2;heap lo={{0},0,1},hi={{0},0,0};for(size_t i=0;i<n;i++){int64_t x=input[i+1];if(hi.n&&x<hi.v[0])push(&lo,x);else push(&hi,x);if(lo.n>hi.n+1)push(&hi,pop(&lo));else if(hi.n>lo.n+1)push(&lo,pop(&hi));int64_t m=lo.n==hi.n?(lo.v[0]+hi.v[0])/2:(lo.n>hi.n?lo.v[0]:hi.v[0]);store(m,output,i*8);}return (int64_t)(n*8);}
