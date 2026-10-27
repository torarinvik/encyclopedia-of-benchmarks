#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n=8,max_h=8,max_input=82,max_output=72;
constexpr std::int64_t input_scale=1000000;
std::int64_t gcd64(std::int64_t a,std::int64_t b){while(b){const auto r=a%b;a=b;b=r;}return a;}
void put64(std::uint8_t*out,std::size_t at,std::int64_t value){std::uint64_t bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t sensor_energy_balance_estimator_trace(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(input==nullptr||length<4||length>max_input)return -1;
    const auto n64=input[0],h64=input[1];if(n64<1||n64>8||h64<1||h64>8||length!=2+static_cast<std::size_t>(n64)+static_cast<std::size_t>(h64)+static_cast<std::size_t>(n64)*static_cast<std::size_t>(h64))return -1;
    const std::size_t n=static_cast<std::size_t>(n64),h=static_cast<std::size_t>(h64);std::int64_t lambda[max_n]{},sum=0;
    for(std::size_t i=0;i<n;++i){lambda[i]=input[2+i];if(lambda[i]<0||lambda[i]>input_scale)return -1;sum+=lambda[i];}if(sum!=input_scale)return -1;
    const std::uint64_t full=(std::uint64_t{1}<<n)-1U;const std::size_t path_at=2+n;
    for(std::size_t t=0;t<h;++t){const auto mask=input[path_at+t];if(mask<=0||(static_cast<std::uint64_t>(mask)&~full)!=0)return -1;}
    std::int64_t lcm=1;for(std::int64_t t=2;t<=h64;++t)lcm=(lcm/gcd64(lcm,t))*t;const std::int64_t q=input_scale*lcm;const std::size_t draw_at=path_at+h;
    for(std::size_t i=0;i<n*h;++i)if(input[draw_at+i]<0||input[draw_at+i]>=q)return -1;
    std::int64_t state[max_n]{};for(std::size_t i=0;i<n;++i)state[i]=lambda[i]*lcm;
    for(std::size_t t=0;t<h;++t){const std::int64_t divisor=static_cast<std::int64_t>(t)+1,delta=q/divisor;const auto path=static_cast<std::uint64_t>(input[path_at+t]);for(std::size_t i=0;i<n;++i){if(state[i]<0||state[i]>q)return -1;const std::int64_t r=input[draw_at+t*n+i]<state[i]?1:0;const std::int64_t x=static_cast<std::int64_t>((path>>i)&1U);const auto updated=state[i]+(x-r)*delta;if(updated<0||updated>q)return -1;state[i]=updated;}}
    const std::size_t bytes=8*(1+n);if(output==nullptr||capacity<bytes)return -2;std::uint8_t staged[max_output];put64(staged,0,q);for(std::size_t i=0;i<n;++i)put64(staged,8*(i+1),state[i]);for(std::size_t i=0;i<bytes;++i)output[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
