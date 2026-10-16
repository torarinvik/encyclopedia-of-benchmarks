#include <cstddef>
#include <cstdint>
extern "C" std::int64_t naive_pattern_search(const std::int64_t* v, std::size_t n) noexcept {
    if (!v || n < 2 || n > 512) return -2;
    const auto tn=v[0], pn=v[1];
    if (tn < 0 || tn > 255 || pn < 0 || pn > tn || n != static_cast<std::size_t>(2+tn+pn)) return -2;
    for (std::size_t i=0;i<static_cast<std::size_t>(tn+pn);++i) if (v[2+i] < 0 || v[2+i] > 127) return -2;
    if (pn == 0) return -1;
    for (std::int64_t start=0;start<=tn-pn;++start) {
        std::int64_t j=0;
        while (j<pn && v[2+start+j]==v[2+tn+j]) ++j;
        if (j==pn) return start;
    }
    return -1;
}
