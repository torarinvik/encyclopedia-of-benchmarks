#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length=256, hash_capacity=1024;
void store_i64_le(std::uint8_t* out,std::size_t offset,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));}
std::size_t hash_key(std::int64_t key){auto bucket=key%static_cast<std::int64_t>(hash_capacity);if(bucket<0)bucket+=static_cast<std::int64_t>(hash_capacity);return static_cast<std::size_t>(bucket);}
bool contains_sum(const std::int64_t* prefix,std::size_t n,std::int64_t target){std::int64_t keys[hash_capacity]{};bool used[hash_capacity]{};auto slot=hash_key(0);used[slot]=true;keys[slot]=0;for(std::size_t end=1;end<=n;++end){auto wanted=prefix[end]-target;slot=hash_key(wanted);while(used[slot]&&keys[slot]!=wanted)slot=(slot+1)%hash_capacity;if(used[slot])return true;slot=hash_key(prefix[end]);while(used[slot]&&keys[slot]!=prefix[end])slot=(slot+1)%hash_capacity;if(!used[slot]){used[slot]=true;keys[slot]=prefix[end];}}return false;}
}
extern "C" std::int64_t prefix_sum(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if(!input||length<2||input[0]<0||input[0]>2||input[1]<0||input[1]>static_cast<std::int64_t>(max_length))return -1;
    auto op=input[0];auto n=static_cast<std::size_t>(input[1]);auto expected=2+n+(op==1?2:op==2?1:0);if(length!=expected||(op==1&&n==0))return -1;
    for(std::size_t i=0;i<n;++i)if(input[2+i]<INT32_MIN||input[2+i]>INT32_MAX)return -1;
    if(op==1){auto left=input[2+n],right=input[3+n];if(left<0||right<left||static_cast<std::uint64_t>(right)>=n)return -1;}
    else if(op==2&&(input[2+n]<-INT64_C(1000000000000)||input[2+n]>INT64_C(1000000000000)))return -1;
    std::int64_t prefix[max_length+1]{};for(std::size_t i=0;i<n;++i)prefix[i+1]=prefix[i]+input[2+i];
    auto words=op==0?n:std::size_t(1);if(capacity<words*8||(words&&output==nullptr))return -2;
    if(op==0){for(std::size_t i=0;i<n;++i)store_i64_le(output,i*8,prefix[i+1]);return static_cast<std::int64_t>(n);}
    auto result=op==1?prefix[static_cast<std::size_t>(input[3+n])+1]-prefix[static_cast<std::size_t>(input[2+n])]:static_cast<std::int64_t>(contains_sum(prefix,n,input[2+n]));
    store_i64_le(output,0,result);return 1;
}
