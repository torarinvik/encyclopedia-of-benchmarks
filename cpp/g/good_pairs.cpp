#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_n = 256, value_limit = 1'000'000; }

extern "C" std::int64_t good_pairs(const std::int64_t* packed, std::size_t length) noexcept {
    if (packed == nullptr || length == 0 || length > 257) return -1;
    const std::int64_t n = packed[0];
    if (n < 0 || n > max_n || length != static_cast<std::size_t>(n) + 1) return -1;
    for (std::int64_t i = 0; i < n; ++i)
        if (packed[i + 1] < -value_limit || packed[i + 1] > value_limit) return -1;
    std::int64_t count = 0;
    for (std::int64_t i = 0; i < n; ++i)
        for (std::int64_t j = i + 1; j < n; ++j)
            if (packed[i + 1] == packed[j + 1]) ++count;
    return count;
}
