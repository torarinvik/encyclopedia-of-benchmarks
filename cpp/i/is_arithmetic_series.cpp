#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_length=64; constexpr std::int64_t bound=1'000'000; }
extern "C" std::int64_t is_arithmetic_series(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length==0 || length>max_length) return -1;
    for (std::size_t i=0;i<length;++i) if(values[i]<-bound || values[i]>bound) return -1;
    if(length==1) return 1;
    const auto difference=values[1]-values[0];
    for(std::size_t i=1;i+1<length;++i) if(values[i+1]-values[i]!=difference) return 0;
    return 1;
}
