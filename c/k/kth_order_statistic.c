#include <stddef.h>
#include <stdint.h>
static int64_t select_k(int64_t*a,size_t n,int64_t k){if(n==1)return a[0];int64_t p=a[0],small[64],big[64];size_t ns=0,nb=0;for(size_t i=1;i<n;i++){if(a[i]<p)small[ns++]=a[i];else if(a[i]>p)big[nb++]=a[i];}if(k==(int64_t)ns+1)return p;if(k<=(int64_t)ns)return select_k(small,ns,k);return select_k(big,nb,k-(int64_t)ns-1);}
int64_t kth_order_statistic(const int64_t*v,size_t n){if(!v||n<2||n>65)return -1;int64_t k=v[0],a[64];if(k<1||k>(int64_t)(n-1))return -1;for(size_t i=1;i<n;i++){if(v[i]<-10000||v[i]>10000)return -1;for(size_t j=1;j<i;j++)if(v[j]==v[i])return -1;a[i-1]=v[i];}return select_k(a,n-1,k);}
