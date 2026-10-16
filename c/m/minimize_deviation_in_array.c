#include <stddef.h>
#include <stdint.h>
static void push(int64_t*h,size_t*n,int64_t x){size_t i=(*n)++;while(i&&h[(i-1)/2]<x){h[i]=h[(i-1)/2];i=(i-1)/2;}h[i]=x;}
static int64_t pop(int64_t*h,size_t*n){int64_t top=h[0],x=h[--*n];size_t i=0;while(2*i+1<*n){size_t c=2*i+1;if(c+1<*n&&h[c+1]>h[c])c++;if(h[c]<=x)break;h[i]=h[c];i=c;}if(*n)h[i]=x;return top;}
int64_t minimize_deviation_in_array(const int64_t*v,size_t n){if(!v||n<2||n>65||v[0]<1||v[0]>64||n!=(size_t)v[0]+1)return -1;size_t count=(size_t)v[0],hn=0;int64_t h[64],low=INT64_MAX;for(size_t i=0;i<count;i++){int64_t x=v[i+1];if(x<1||x>1000000)return -1;if(x&1)x*=2;if(x<low)low=x;push(h,&hn,x);}int64_t best=h[0]-low;while((h[0]&1)==0){int64_t x=pop(h,&hn)/2;if(x<low)low=x;push(h,&hn,x);int64_t d=h[0]-low;if(d<best)best=d;}return best;}
