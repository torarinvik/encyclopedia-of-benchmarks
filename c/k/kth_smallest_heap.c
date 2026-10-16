#include <stddef.h>
#include <stdint.h>
static void down(int64_t*h,size_t n,size_t i){for(;;){size_t l=2*i+1,r=l+1,m=i;if(l<n&&h[l]>h[m])m=l;if(r<n&&h[r]>h[m])m=r;if(m==i)return;int64_t t=h[i];h[i]=h[m];h[m]=t;i=m;}}
int64_t kth_smallest_heap(const int64_t*v,size_t n){if(!v||n<2||n>65)return -1;int64_t k=v[0],h[64];if(k<1||k>=n)return -1;size_t m=(size_t)k;for(size_t i=0;i<m;i++){if(v[i+1]<-100000||v[i+1]>100000)return -1;h[i]=v[i+1];}for(size_t i=m/2;i>0;i--)down(h,m,i-1);for(size_t i=m+1;i<n;i++){int64_t x=v[i];if(x< -100000||x>100000)return -1;if(x<=h[0]){h[0]=x;down(h,m,0);}}return h[0];}
