/* Evaluate net present value for each supplied discount rate. */
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
namespace {
void put_f64_le(std::uint8_t *out,std::size_t offset,double value){std::uint64_t bits;std::memcpy(&bits,&value,8);for(std::size_t b=0;b<8;++b)out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t npv_sensitivity(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(!input||length<2||input[0]<0||input[0]>64||input[1]<0||input[1]>32)return -1;
    const auto n=static_cast<std::size_t>(input[0]),rates=static_cast<std::size_t>(input[1]);
    if(length!=2+n+rates)return -1;
    for(std::size_t t=0;t<n;++t)if(input[2+t]<-1000000||input[2+t]>1000000)return -1;
    for(std::size_t r=0;r<rates;++r)if(input[2+n+r]<0||input[2+n+r]>1000)return -1;
    if(capacity<rates*8||(rates>0&&!output))return -2;
    for(std::size_t r=0;r<rates;++r){double rate=static_cast<double>(input[2+n+r])/10000.0,total=0.0;for(std::size_t t=0;t<n;++t){double term=static_cast<double>(input[2+t])/std::pow(1.0+rate,static_cast<double>(t));total+=term;}put_f64_le(output,r*8,total);}
    return static_cast<std::int64_t>(rates*8);
}
