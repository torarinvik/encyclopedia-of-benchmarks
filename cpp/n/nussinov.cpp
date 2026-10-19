#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 128;
}

extern "C" std::int64_t nussinov(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    std::int64_t bases[MAX_N] = {};
    std::int64_t table[MAX_N][MAX_N] = {};
    for (std::size_t i = 0; i < n; ++i) bases[i] = static_cast<std::int64_t>((i + 1) % 4);

    for (std::size_t i = n; i > 0;) {
        --i;
        for (std::size_t j = i + 1; j < n; ++j) {
            std::int64_t score = table[i][j - 1];
            if (i + 1 < n) {
                if (table[i + 1][j] > score) score = table[i + 1][j];
                std::int64_t inside = table[i + 1][j - 1];
                if (i < j - 1 && bases[i] + bases[j] == 3) ++inside;
                if (inside > score) score = inside;
            }
            for (std::size_t k = i + 1; k < j; ++k) {
                const std::int64_t split = table[i][k] + table[k + 1][j];
                if (split > score) score = split;
            }
            table[i][j] = score;
        }
    }

    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = i; j < n; ++j)
            checksum += table[i][j];
    return checksum;
}
