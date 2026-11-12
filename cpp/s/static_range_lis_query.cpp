#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX = 128, QMAX = 32;
std::size_t lower_bound_i64(const std::int64_t *a, std::size_t n, std::int64_t x) {
    std::size_t lo = 0, hi = n;
    while (lo < hi) {
        auto mid = lo + (hi - lo) / 2;
        if (a[mid] < x) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}
void write_i64_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t static_range_lis_query(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 195) return -1;
    auto n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > 128 || q64 < 1 || q64 > 32) return -1;
    auto n = static_cast<std::size_t>(n64), q = static_cast<std::size_t>(q64);
    if (length != 2 + n + 2 * q) return -1;
    std::int64_t permutation[NMAX], left[QMAX], right[QMAX];
    bool seen[NMAX]{};
    for (std::size_t i = 0; i < n; ++i) {
        auto value = input[2 + i];
        if (value < 0 || value >= n64 || seen[static_cast<std::size_t>(value)]) return -1;
        seen[static_cast<std::size_t>(value)] = true;
        permutation[i] = value;
    }
    std::size_t off = 2 + n;
    for (std::size_t k = 0; k < q; ++k) {
        left[k] = input[off++]; right[k] = input[off++];
        if (left[k] < 0 || left[k] > right[k] || right[k] > n64) return -1;
    }
    std::int64_t answers[QMAX], tails[NMAX];
    for (std::size_t k = 0; k < q; ++k) {
        std::size_t count = 0;
        for (auto i = static_cast<std::size_t>(left[k]); i < static_cast<std::size_t>(right[k]); ++i) {
            auto at = lower_bound_i64(tails, count, permutation[i]);
            tails[at] = permutation[i];
            if (at == count) ++count;
        }
        answers[k] = static_cast<std::int64_t>(count);
    }
    auto bytes = 8 * q;
    if (!output || capacity < bytes) return -2;
    for (std::size_t k = 0; k < q; ++k) write_i64_le(output, 8 * k, answers[k]);
    return static_cast<std::int64_t>(bytes);
}
