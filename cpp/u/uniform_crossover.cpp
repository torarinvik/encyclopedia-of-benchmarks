#include <cstddef>
#include <cstdint>
static void put_i64_le(std::uint8_t* output,std::size_t offset,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t byte=0;byte<8;++byte)output[offset+byte]=static_cast<std::uint8_t>(bits>>(8*byte));}
extern "C" std::int64_t uniform_crossover(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<4||length>193)return -1;const auto n=input[0];if(n<1||n>64||length!=static_cast<std::size_t>(1+3*n))return -1;
    for(std::size_t i=0;i<static_cast<std::size_t>(n);++i)if(input[1+i]!=0&&input[1+i]!=1)return -1;
    for(std::size_t i=0;i<static_cast<std::size_t>(2*n);++i)if(input[1+static_cast<std::size_t>(n)+i]<INT64_C(-2147483648)||input[1+static_cast<std::size_t>(n)+i]>INT64_C(2147483647))return -1;
    const auto count=static_cast<std::size_t>(n),bytes=16*static_cast<std::size_t>(n);if(output==nullptr||capacity<bytes)return -2;
    for(std::size_t i=0;i<count;++i){auto alpha=input[1+i],p=input[1+count+i],q=input[1+2*count+i];auto c1=alpha?p:q,c2=alpha?q:p;put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2);}return static_cast<std::int64_t>(bytes);}
