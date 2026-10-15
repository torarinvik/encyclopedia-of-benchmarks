#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_length=64; constexpr std::int64_t bound=1'000'000; constexpr double invalid=-1.0e300; }
extern "C" double arithmetic_mean(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length==0 || length>max_length) return invalid;
    std::int64_t total=0;
    for(std::size_t i=0;i<length;++i) { if(values[i]<-bound || values[i]>bound) return invalid; total+=values[i]; }
    return static_cast<double>(total)/static_cast<double>(length);
}
