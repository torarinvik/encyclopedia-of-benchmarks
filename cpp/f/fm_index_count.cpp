#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxText = 32, MaxPattern = 8, MaxInput = 42;
bool suffix_less(const std::int64_t *s, std::size_t n, std::size_t a, std::size_t b) {
    while (a < n && b < n) { if (s[a] != s[b]) return s[a] < s[b]; ++a; ++b; }
    return a == n && b != n;
}
}

extern "C" std::int64_t fm_index_count(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MaxInput) return -1;
    const auto n0 = input[0];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MaxText) || length < static_cast<std::size_t>(n0) + 3) return -1;
    const auto n = static_cast<std::size_t>(n0), m_at = n + 1;
    const auto m0 = input[m_at];
    if (m0 < 1 || m0 > static_cast<std::int64_t>(MaxPattern) || length != m_at + 1 + static_cast<std::size_t>(m0)) return -1;
    const auto m = static_cast<std::size_t>(m0), total = n + 1;
    std::int64_t s[MaxText + 1], pattern[MaxPattern];
    for (std::size_t i = 0; i < n; ++i) { if (input[1 + i] < 1 || input[1 + i] > 4) return -1; s[i] = input[1 + i]; }
    for (std::size_t i = 0; i < m; ++i) { if (input[m_at + 1 + i] < 1 || input[m_at + 1 + i] > 4) return -1; pattern[i] = input[m_at + 1 + i]; }
    s[n] = 0;
    if (output == nullptr || capacity < 8) return -2;
    std::size_t sa[MaxText + 1];
    for (std::size_t i = 0; i < total; ++i) sa[i] = i;
    for (std::size_t i = 1; i < total; ++i) {
        const auto key = sa[i]; auto j = i;
        while (j > 0 && suffix_less(s, total, key, sa[j - 1])) { sa[j] = sa[j - 1]; --j; }
        sa[j] = key;
    }
    std::int64_t bwt[MaxText + 1]; std::size_t freq[5]{};
    for (std::size_t i = 0; i < total; ++i) { bwt[i] = s[(sa[i] + total - 1) % total]; ++freq[static_cast<std::size_t>(bwt[i])]; }
    std::size_t c[5]{}, sum = 0;
    for (std::size_t x = 0; x < 5; ++x) { c[x] = sum; sum += freq[x]; }
    std::size_t left = 0, right = total;
    for (std::size_t k = m; k > 0; --k) {
        const auto symbol = static_cast<std::size_t>(pattern[k - 1]); std::size_t rl = 0, rr = 0;
        for (std::size_t i = 0; i < left; ++i) if (static_cast<std::size_t>(bwt[i]) == symbol) ++rl;
        for (std::size_t i = 0; i < right; ++i) if (static_cast<std::size_t>(bwt[i]) == symbol) ++rr;
        left = c[symbol] + rl; right = c[symbol] + rr;
        if (left == right) break;
    }
    const auto count = static_cast<std::uint64_t>(right - left);
    for (std::size_t i = 0; i < 8; ++i) output[i] = static_cast<std::uint8_t>(count >> (8 * i));
    return 8;
}
