#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t S=1000000;
std::int64_t trunc_div(std::int64_t a,std::int64_t b){return a<0?-((-a)/b):a/b;}
std::int64_t floor_sqrt(std::int64_t value){std::int64_t low=0,high=13000001;while(low+1<high){auto middle=(low+high)/2;if(middle<=value/middle)low=middle;else high=middle;}return low;}
void put64(std::uint8_t*out,std::size_t pos,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t j=0;j<8;++j){out[pos+j]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t private_noisy_power_iteration(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept {
    constexpr std::size_t N=4,L=4,MAX_INPUT=39;
    if(!in||len<11||len>MAX_INPUT)return -1;
    auto n64=in[0],l64=in[1],sigma=in[2];
    if(n64<2||n64>N||l64<1||l64>L||sigma<0||sigma>S||len!=3+static_cast<std::size_t>(n64*n64+n64+l64*n64))return -1;
    auto n=static_cast<std::size_t>(n64),rounds=static_cast<std::size_t>(l64),vstart=3+n*n,nstart=vstart+n;
    std::int64_t a[N*N]{},x[N]{},noise[L*N]{};
    for(std::size_t i=0;i<n*n;++i){a[i]=in[3+i];if(a[i]<-S||a[i]>S)return -1;}
    for(std::size_t i=0;i<n;++i)for(std::size_t j=0;j<n;++j)if(a[i*n+j]!=a[j*n+i])return -1;
    std::int64_t norm=0;for(std::size_t i=0;i<n;++i){x[i]=in[vstart+i];if(x[i]<-S||x[i]>S)return -1;norm+=x[i]*x[i];}if(norm!=S*S)return -1;
    for(std::size_t i=0;i<rounds*n;++i){noise[i]=in[nstart+i];if(noise[i]<-2*S||noise[i]>2*S)return -1;}
    std::int64_t y[N]{};
    for(std::size_t step=0;step<rounds;++step){std::int64_t norm_sq=0;for(std::size_t i=0;i<n;++i){auto sum=sigma*noise[step*n+i];for(std::size_t j=0;j<n;++j)sum+=a[i*n+j]*x[j];y[i]=trunc_div(sum,S);norm_sq+=y[i]*y[i];}if(norm_sq==0)return -1;auto radius=floor_sqrt(norm_sq);for(std::size_t i=0;i<n;++i)x[i]=trunc_div(y[i]*S,radius);}
    auto bytes=8*n;if(!out||cap<bytes)return -2;std::uint8_t staged[8*N]{};for(std::size_t i=0;i<n;++i)put64(staged,8*i,x[i]);for(std::size_t i=0;i<bytes;++i)out[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
