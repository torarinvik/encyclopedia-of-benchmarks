#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN=5, MaxM=4, MaxSubsets=32, MaxInput=131;
void storeI64LE(std::uint8_t* out, std::size_t at, std::int64_t value) noexcept {
    auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}
}
}

extern "C" std::int64_t submodular_ranking_greedy(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if(!input||length<2||length>MaxInput)return -1;
    const auto n64=input[0],m64=input[1];
    if(n64<1||n64>5||m64<1||m64>4)return -1;
    const auto n=static_cast<std::size_t>(n64),m=static_cast<std::size_t>(m64),size=std::size_t(1)<<n;
    if(length!=2+m*size)return -1;
    std::int64_t f[MaxM][MaxSubsets]{};
    for(std::size_t i=0;i<m;++i){
        for(std::size_t a=0;a<size;++a){auto v=input[2+i*size+a];if(v<0||v>8)return -1;f[i][a]=v;}
        if(f[i][0]!=0||f[i][size-1]!=8)return -1;
        for(std::size_t a=0;a<size;++a)for(std::size_t bit=0;bit<n;++bit){auto e=std::size_t(1)<<bit;if(!(a&e)&&f[i][a]>f[i][a|e])return -1;}
        for(std::size_t a=0;a<size;++a)for(std::size_t b=0;b<size;++b){if((a&b)!=a)continue;for(std::size_t bit=0;bit<n;++bit){auto e=std::size_t(1)<<bit;if(!(b&e)&&f[i][a|e]-f[i][a]<f[i][b|e]-f[i][b])return -1;}}
    }
    const auto outBytes=8*(1+n+m);if(!output||capacity<outBytes)return -2;
    std::size_t order[MaxN]{},mask=0;std::int64_t times[MaxM]{},total=0;
    for(std::size_t t=1;t<=n;++t){
        std::size_t winner=0;std::int64_t bestNum=-1,bestDen=1;
        for(std::size_t e=0;e<n;++e){auto bit=std::size_t(1)<<e;if(mask&bit)continue;std::int64_t num=0,den=1;
            for(std::size_t i=0;i<m;++i){auto cur=f[i][mask];if(cur==8)continue;auto d=8-cur,gain=f[i][mask|bit]-cur;num=num*d+gain*den;den*=d;}
            if(bestNum<0||num*bestDen>bestNum*den){winner=e;bestNum=num;bestDen=den;}
        }
        mask|=std::size_t(1)<<winner;order[t-1]=winner;
        for(std::size_t i=0;i<m;++i)if(times[i]==0&&f[i][mask]==8){times[i]=static_cast<std::int64_t>(t);total+=static_cast<std::int64_t>(t);}
    }
    storeI64LE(output,0,total);for(std::size_t j=0;j<n;++j)storeI64LE(output,8*(1+j),static_cast<std::int64_t>(order[j]));
    for(std::size_t i=0;i<m;++i)storeI64LE(output,8*(1+n+i),times[i]);return static_cast<std::int64_t>(outBytes);
}
