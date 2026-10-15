#include <cstddef>
#include <cstdint>

extern "C" std::int64_t luhn_validate(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length<1)return -1;const auto n=input[0];
    if(n<2||n>64||(n&1)!=0||length!=static_cast<std::size_t>(n+1))return -1;
    std::int64_t sum=0;
    for(std::int64_t i=0;i<n;++i){auto digit=input[i+1];if(digit<0||digit>9)return -1;if((i&1)==0){digit*=2;if(digit>9)digit-=9;}sum+=digit;}
    return sum%10==0?1:0;
}
