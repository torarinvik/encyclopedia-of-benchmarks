#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n=8,max_steps=8,max_input=76;
void put64(std::uint8_t*out,std::size_t at,std::int64_t value){std::uint64_t bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t distributed_coupon_collection_replay(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(input==nullptr||length<4||length>max_input)return -1;
    const auto n64=input[0],c64=input[1],copies=input[2],steps64=input[3];
    if(n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>8||length!=4+static_cast<std::size_t>(n64)+static_cast<std::size_t>(n64)*static_cast<std::size_t>(steps64))return -1;
    const std::size_t n=static_cast<std::size_t>(n64),coupons=static_cast<std::size_t>(c64),steps=static_cast<std::size_t>(steps64);const std::uint64_t full=(std::uint64_t{1}<<coupons)-1U;
    std::uint64_t bins[max_n]{};for(std::size_t b=0;b<n;++b){const auto raw=input[4+b];if(raw<0||(static_cast<std::uint64_t>(raw)&~full)!=0)return -1;bins[b]=static_cast<std::uint64_t>(raw);}
    for(std::size_t coupon=0;coupon<coupons;++coupon){std::size_t count=0;for(std::size_t b=0;b<n;++b)if((bins[b]>>coupon)&1U)++count;if(count<static_cast<std::size_t>(copies))return -1;}
    const std::size_t tape_at=4+n;for(std::size_t i=0;i<n*steps;++i)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    if(output==nullptr||capacity<16)return -2;
    std::uint64_t collected=0;std::int64_t singleton_steps=0;
    for(std::size_t step=0;step<steps;++step){std::size_t open_count=0,opened_bin=0;for(std::size_t bin=0;bin<n;++bin)if(input[tape_at+step*n+bin]==1){++open_count;opened_bin=bin;}if(open_count==1){++singleton_steps;collected|=bins[opened_bin];}}
    std::uint8_t staged[16];put64(staged,0,static_cast<std::int64_t>(collected));put64(staged,8,singleton_steps);for(std::size_t i=0;i<16;++i)output[i]=staged[i];return 16;
}
