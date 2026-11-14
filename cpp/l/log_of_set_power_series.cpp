#include <array>
#include <cstddef>
#include <cstdint>
extern "C" int64_t log_of_set_power_series(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    constexpr int64_t p=998244353;
    if (!input || length<2 || length>33 || input[0]<0 || input[0]>5) return -1;
    int size=1<<static_cast<int>(input[0]);
    if (length!=1+static_cast<size_t>(size) || input[1]!=1) return -1;
    for (int i=0;i<size;++i) if (input[1+i]<0 || input[1+i]>=p) return -1;
    if (!output || capacity<8*static_cast<size_t>(size)) return -2;
    std::array<int64_t,32> result{};
    for (int mask=1;mask<size;++mask) {
        int pivot=mask & -mask; int64_t sum=0;
        for (int sub=(mask-1)&mask;sub;sub=(sub-1)&mask)
            if (sub&pivot) sum=(sum+result[sub]*input[1+(mask^sub)])%p;
        result[mask]=(input[1+mask]-sum+p)%p;
    }
    for (int i=0;i<size;++i) {
        auto bits=static_cast<uint64_t>(result[i]);
        for (size_t byte=0;byte<8;++byte) output[8*static_cast<size_t>(i)+byte]=static_cast<uint8_t>(bits >> (8*byte));
    }
    return 8*size;
}
