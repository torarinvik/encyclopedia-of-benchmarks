#include <algorithm>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t longestpalindrome(const std::int64_t *v, std::size_t n) {
    if (v == nullptr || n < 1 || n > 65) return -1;
    const auto count = v[0];
    if (count < 0 || count > 64 || n != static_cast<std::size_t>(count) + 1) return -1;
    std::int64_t text[64];
    std::size_t length = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const auto ch = v[i + 1];
        if (ch < 32 || ch > 126 || ch == 35) return -1;
        if (ch != 32) text[length++] = ch;
    }
    std::int64_t transformed[129];
    const std::size_t size = 2 * length + 1;
    for (std::size_t i = 0; i < size; ++i) transformed[i] = (i % 2 == 0) ? -1 : text[i / 2];
    std::size_t radius[129] = {};
    std::size_t center = 0, right = 0, best = 0;
    for (std::size_t i = 0; i < size; ++i) {
        if (i < right) radius[i] = std::min(radius[2 * center - i], right - i);
        while (i >= radius[i] + 1 && i + radius[i] + 1 < size
               && transformed[i - radius[i] - 1] == transformed[i + radius[i] + 1]) ++radius[i];
        best = std::max(best, radius[i]);
        if (i + radius[i] > right) { center = i; right = i + radius[i]; }
    }
    return static_cast<std::int64_t>(best);
}
