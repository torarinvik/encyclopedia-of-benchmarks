#include <cstddef>
#include <cstdint>
extern "C" std::int64_t fast_walsh_hadamard_transform(const std::int64_t *v,std::size_t len,std::uint8_t *out,std::size_t cap) noexcept {
 if(!v||len<2||len>130||(v[0]!=0&&v[0]!=1)||v[1]<1||v[1]>128)return -1;
 auto n=static_cast<std::size_t>(v[1]);if((n&(n-1))||len!=n+2)return -1;
 std::int64_t a[128];for(std::size_t i=0;i<n;i++){if(v[i+2]<-10000||v[i+2]>10000)return -1;a[i]=v[i+2];}
 for(std::size_t h=1;h<n;h*=2)for(std::size_t b=0;b<n;b+=2*h)for(std::size_t j=0;j<h;j++){auto x=a[b+j],y=a[b+j+h];a[b+j]=x+y;a[b+j+h]=x-y;}
 if(v[0])for(std::size_t i=0;i<n;i++){if(a[i]%static_cast<std::int64_t>(n))return -1;a[i]/=static_cast<std::int64_t>(n);}
 if(n*8>cap||!out)return -2;for(std::size_t i=0;i<n;i++){auto x=static_cast<std::uint64_t>(a[i]);for(std::size_t k=0;k<8;k++)out[i*8+k]=static_cast<std::uint8_t>(x>>(8*k));}return static_cast<std::int64_t>(n);
}
