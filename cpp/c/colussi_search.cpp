#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 4096;
constexpr std::size_t max_pattern_length = 128;
constexpr std::size_t max_parseable_length = 4227;
constexpr std::size_t table_size = max_pattern_length + 1;

std::int64_t preprocess(const std::int64_t *pattern, std::size_t m,
                        std::int64_t *h, std::int64_t *next,
                        std::int64_t *shift) noexcept {
    std::int64_t hmax[table_size]{};
    std::int64_t kmin[table_size]{};
    std::int64_t nhd0[table_size]{};
    std::int64_t rmin[table_size]{};
    std::int64_t i = 1;
    std::int64_t k = 1;

    while (static_cast<std::size_t>(k) <= m) {
        while (pattern[i] == pattern[i - k]) ++i;
        hmax[k] = i;
        std::int64_t q = k + 1;
        while (hmax[q - k] + k < i) {
            hmax[q] = hmax[q - k] + k;
            ++q;
        }
        k = q;
        if (k == i + 1) i = k;
    }

    for (std::size_t index = 0; index <= m; ++index) kmin[index] = 0;
    for (i = static_cast<std::int64_t>(m); i >= 1; --i) {
        if (static_cast<std::size_t>(hmax[i]) < m) kmin[hmax[i]] = i;
    }

    std::int64_t r = static_cast<std::int64_t>(m);
    for (i = static_cast<std::int64_t>(m) - 1; i >= 0; --i) {
        if (static_cast<std::size_t>(hmax[i + 1]) == m) r = i + 1;
        rmin[i] = kmin[i] == 0 ? r : 0;
    }

    std::int64_t s = -1;
    r = static_cast<std::int64_t>(m);
    for (i = 0; static_cast<std::size_t>(i) < m; ++i) {
        if (kmin[i] == 0) h[--r] = i;
        else h[++s] = i;
    }
    const std::int64_t nd = s;

    for (i = 0; i <= nd; ++i) shift[i] = kmin[h[i]];
    for (i = nd + 1; static_cast<std::size_t>(i) < m; ++i)
        shift[i] = rmin[h[i]];
    shift[m] = rmin[0];

    s = 0;
    for (i = 0; static_cast<std::size_t>(i) < m; ++i) {
        nhd0[i] = s;
        if (kmin[i] > 0) ++s;
    }

    for (i = 0; i <= nd; ++i) next[i] = nhd0[h[i] - kmin[h[i]]];
    for (i = nd + 1; static_cast<std::size_t>(i) < m; ++i)
        next[i] = nhd0[static_cast<std::int64_t>(m) - rmin[h[i]]];
    next[m] = nhd0[static_cast<std::int64_t>(m) - rmin[h[m - 1]]];
    return nd;
}
} // namespace

extern "C" std::int64_t colussi_search(const std::int64_t *input,
                                       std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_length) {
        return -1;
    }
    const std::int64_t text_length_value = input[0];
    const std::int64_t pattern_length_value = input[1];
    if (text_length_value < 0
        || text_length_value > static_cast<std::int64_t>(max_text_length)
        || pattern_length_value < 1
        || pattern_length_value > static_cast<std::int64_t>(max_pattern_length)) {
        return -1;
    }
    const auto n = static_cast<std::size_t>(text_length_value);
    const auto m = static_cast<std::size_t>(pattern_length_value);
    if (length != 2 + n + m) return -1;

    const std::size_t pattern_start = 2 + n;
    std::int64_t pattern[table_size]{};
    for (std::size_t index = 0; index < n; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (std::size_t index = 0; index < m; ++index) {
        const std::int64_t symbol = input[pattern_start + index];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[index] = symbol;
    }
    pattern[m] = 4;

    std::int64_t h[table_size]{};
    std::int64_t next[table_size]{};
    std::int64_t shift[table_size]{};
    const std::int64_t nd = preprocess(pattern, m, h, next, shift);

    std::int64_t match_count = 0;
    std::int64_t sum_offsets = 0;
    std::int64_t xor_offsets = 0;
    if (n >= m) {
        std::int64_t i = 0;
        std::int64_t j = 0;
        std::int64_t last = -1;
        while (static_cast<std::size_t>(j) <= n - m) {
            while (static_cast<std::size_t>(i) < m && last < j + h[i]
                   && pattern[h[i]] == input[2 + static_cast<std::size_t>(j)
                                              + static_cast<std::size_t>(h[i])]) {
                ++i;
            }
            if (static_cast<std::size_t>(i) >= m) {
                ++match_count;
                sum_offsets += j;
                xor_offsets ^= j;
                i = static_cast<std::int64_t>(m);
            } else if (last >= j + h[i]) {
                ++match_count;
                sum_offsets += j;
                xor_offsets ^= j;
                i = static_cast<std::int64_t>(m);
            }
            if (i > nd) last = j + static_cast<std::int64_t>(m) - 1;
            j += shift[i];
            i = next[i];
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
