#include <stddef.h>
#include <stdint.h>
int64_t kth_next_greater_element(const int64_t*v,size_t n){if(!v||n<2||n>8)return -1;int64_t k=v[0];if(k<1||k>7)return -1;size_t m=n-1;for(size_t q=1;q<n;q++)if(v[q]<-15||v[q]>15)return -1;int64_t count=0;for(size_t i=0;i<m;i++){int64_t cur=v[i+1];size_t pos=i+1;int ok=1;for(int64_t z=0;z<k;z++){while(pos<m&&v[pos+1]<=cur)pos++;if(pos==m){ok=0;break;}cur=v[pos+1];pos++;}if(ok)count++;}return count;}
