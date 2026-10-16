#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kth_next_greater_element(const std::int64_t*v,std::size_t n){if(!v||n<2||n>8)return -1;auto k=v[0];if(k<1||k>7)return -1;auto m=n-1;for(std::size_t q=1;q<n;q++)if(v[q]<-15||v[q]>15)return -1;std::int64_t count=0;for(std::size_t i=0;i<m;i++){auto cur=v[i+1];std::size_t pos=i+1;bool ok=true;for(std::int64_t z=0;z<k;z++){while(pos<m&&v[pos+1]<=cur)pos++;if(pos==m){ok=false;break;}cur=v[pos+1];pos++;}if(ok)count++;}return count;}
