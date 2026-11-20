#include <cstddef>
#include <cstdint>

extern "C" std::int64_t berry_ravindran_search(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    const std::size_t m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    for (std::size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 15) return -2;
    if (m > n) return -1;
    const std::size_t p = 2 + n;
    std::size_t shift[289];
    for (std::size_t i = 0; i < 289; ++i) shift[i] = m + 2;
    for (std::size_t a = 0; a < 17; ++a) shift[a * 17 + static_cast<std::size_t>(values[p])] = m + 1;
    for (std::size_t i = 0; i + 1 < m; ++i)
        shift[static_cast<std::size_t>(values[p + i]) * 17 + static_cast<std::size_t>(values[p + i + 1])] = m - i;
    for (std::size_t b = 0; b < 17; ++b)
        shift[static_cast<std::size_t>(values[p + m - 1]) * 17 + b] = 1;
    std::size_t start = 0;
    while (start <= n - m) {
        std::size_t i = 0;
        while (i < m && values[2 + start + i] == values[p + i]) ++i;
        if (i == m) return static_cast<std::int64_t>(start);
        const std::size_t k = start + m;
        if (k >= n) break;
        const std::size_t first = static_cast<std::size_t>(values[2 + k]);
        const std::size_t second = k + 1 < n ? static_cast<std::size_t>(values[2 + k + 1]) : 16;
        start += shift[first * 17 + second];
    }
    return -1;
}
