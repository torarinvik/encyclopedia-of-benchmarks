#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t M=8,E=8,W=8;
std::size_t ihash(const std::int64_t*a,std::size_t n,std::size_t mod){std::uint32_t h=0;std::size_t i=0,first=n<4?n:4;for(;i<first;i++)h=(h<<8)|std::uint32_t(a[i]-32);for(;i<n;i++)h=(h<<5)|(h>>27),h^=std::uint32_t(a[i]-32);return h%mod;}
}
extern "C" std::int64_t cbench_ispell_lookup_chain(const std::int64_t*a,std::size_t len){
 if(!a||len<3||len>108||a[0]<1||a[0]>8||a[1]<1||a[1]>8||a[2]<0||a[2]>8)return -1;auto m=std::size_t(a[0]),q=std::size_t(a[1]),n=std::size_t(a[2]);if(len<3+q+m+2*n)return -1;auto h0=3+q,nx0=h0+m,l0=nx0+n;std::size_t p=l0+n;
 for(std::size_t j=0;j<q;j++)if(a[3+j]<97||a[3+j]>122)return -1;
 std::int64_t heads[M],next[E];std::size_t lens[E],off[E];for(std::size_t b=0;b<m;b++){heads[b]=a[h0+b];if(heads[b]<-1||heads[b]>=std::int64_t(n))return -1;}
 for(std::size_t i=0;i<n;i++){next[i]=a[nx0+i];if(next[i]<-1||next[i]>=std::int64_t(n)||a[l0+i]<1||a[l0+i]>W)return -1;lens[i]=std::size_t(a[l0+i]);if(p+lens[i]>len)return -1;off[i]=p;for(std::size_t j=0;j<lens[i];j++)if(a[p+j]<97||a[p+j]>122)return -1;p+=lens[i];}
 if(p!=len)return -1;bool seen[E]={};std::size_t count=0;for(std::size_t b=0;b<m;b++)for(auto x=heads[b];x!=-1;x=next[std::size_t(x)]){auto i=std::size_t(x);if(seen[i])return -1;seen[i]=true;count++;if(ihash(a+off[i],lens[i],m)!=b)return -1;}if(count!=n)return -1;
 for(auto x=heads[ihash(a+3,q,m)];x!=-1;x=next[std::size_t(x)]){auto i=std::size_t(x);if(lens[i]==q){std::size_t j=0;while(j<q&&a[off[i]+j]==a[3+j])j++;if(j==q)return std::int64_t(i+1);}}return 0;
}
