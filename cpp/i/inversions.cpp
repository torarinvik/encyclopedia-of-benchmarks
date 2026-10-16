#include <cstddef>
#include <cstdint>
extern "C" std::int64_t inversions(const std::int64_t* values, std::size_t length) noexcept {
    if(length>1024||(length&&values==nullptr))return -1; for(std::size_t i=0;i<length;i++)if(values[i]<INT32_MIN||values[i]>INT32_MAX)return -1; std::int64_t count=0; for(std::size_t i=0;i<length;i++)for(std::size_t j=i+1;j<length;j++)if(values[i]>values[j])count++; return count;
}
