#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

extern "C" std::int64_t fast_inverse_sqrt_java_check(const std::int64_t *input,std::size_t length) noexcept {
    if(!input||length!=2)return -1;
    if(input[0]==0){
        if(input[1]<0x00800000LL||input[1]>0x7f7fffffLL)return -1;
        const auto bits=static_cast<std::uint32_t>(input[1]);float number;std::memcpy(&number,&bits,sizeof(number));
        float x=number;const float xhalf=0.5f*x;std::int32_t seed=static_cast<std::int32_t>(bits);seed=0x5f3759df-(seed>>1);const auto seed_bits=static_cast<std::uint32_t>(seed);std::memcpy(&x,&seed_bits,sizeof(x));
        x=x*(1.5f-xhalf*x*x);const float expected=1.0f/static_cast<float>(std::sqrt(static_cast<double>(number)));return x==expected?1:0;
    }
    if(input[0]==1){
        const auto bits=static_cast<std::uint64_t>(input[1]);if(bits<UINT64_C(0x0010000000000000)||bits>UINT64_C(0x7fefffffffffffff))return -1;
        double number;std::memcpy(&number,&bits,sizeof(number));double x=number;const double xhalf=0.5*x;auto seed=static_cast<std::int64_t>(bits);seed=INT64_C(0x5fe6ec85e7de30da)-(seed>>1);const auto seed_bits=static_cast<std::uint64_t>(seed);std::memcpy(&x,&seed_bits,sizeof(x));
        for(int iteration=0;iteration<4;++iteration)x=x*(1.5-xhalf*x*x);x*=number;return x==1.0/std::sqrt(number)?1:0;
    }
    return -1;
}
