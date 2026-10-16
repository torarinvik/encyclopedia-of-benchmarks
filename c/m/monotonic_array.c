#include <stddef.h>
#include <stdint.h>
int64_t monotonic_array(const int64_t *v,size_t n){
 if(n>256||(!v&&n>0))return -1;
 int inc=1,dec=1;
 for(size_t i=0;i<n;i++)if(v[i]<-1000000000LL||v[i]>1000000000LL)return -1;
 for(size_t i=1;i<n;i++){if(v[i-1]>v[i])inc=0;if(v[i-1]<v[i])dec=0;}
 return inc||dec;
}
