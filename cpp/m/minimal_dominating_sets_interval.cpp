#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int MaxN = 12;
bool intersects(const std::int64_t *s, const std::int64_t *e, int a, int b) {
    return s[a] <= e[b] && s[b] <= e[a];
}
}

extern "C" std::int64_t minimal_dominating_sets_interval(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 25) return -1;
    const auto n0 = input[0];
    if (n0 < 1 || n0 > MaxN || length != 1 + 2 * static_cast<std::size_t>(n0)) return -1;
    const int n = static_cast<int>(n0);
    std::int64_t s[MaxN], e[MaxN], min_end = std::numeric_limits<std::int64_t>::max();
    std::int64_t max_start = std::numeric_limits<std::int64_t>::min();
    for (int i = 0; i < n; ++i) {
        s[i] = input[1 + 2 * i]; e[i] = input[2 + 2 * i];
        if (s[i] < -100 || s[i] > 100 || e[i] < -100 || e[i] > 100 || s[i] >= e[i]) return -1;
        if (i > 0 && s[i - 1] >= s[i]) return -1;
        if (e[i] < min_end) min_end = e[i];
        if (s[i] > max_start) max_start = s[i];
        for (int j = 0; j < i; ++j)
            if (s[i] == s[j] || s[i] == e[j] || e[i] == s[j] || e[i] == e[j]) return -1;
    }
    if (output == nullptr || capacity < 8) return -2;
    bool has_next[MaxN]{}; std::int64_t ncs[MaxN]{}, nce[MaxN]{};
    std::int64_t p_single[MaxN];
    for (int i = 0; i < n; ++i) {
        p_single[i] = std::numeric_limits<std::int64_t>::max();
        for (int z = 0; z < n; ++z) {
            if (intersects(s, e, i, z) && e[z] < p_single[i]) p_single[i] = e[z];
            if (s[z] > e[i]) {
                if (!has_next[i] || s[z] < ncs[i]) ncs[i] = s[z];
                if (!has_next[i] || e[z] < nce[i]) nce[i] = e[z];
                has_next[i] = true;
            }
        }
    }
    bool valid[MaxN][MaxN]{}; std::int64_t p_pair[MaxN][MaxN]{};
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) {
        p_pair[i][j] = std::numeric_limits<std::int64_t>::max();
        for (int z = 0; z < n; ++z)
            if (intersects(s, e, j, z) && !intersects(s, e, i, z) && e[z] < p_pair[i][j]) p_pair[i][j] = e[z];
        valid[i][j] = has_next[i] && p_single[i] < s[j] && s[j] <= nce[i] && e[j] >= ncs[i];
    }
    std::int64_t ways[MaxN][MaxN]{};
    for (int j = 1; j < n; ++j) for (int i = 0; i < j; ++i) {
        if (!valid[i][j]) continue;
        if (s[i] <= min_end) ++ways[i][j];
        for (int k = j + 1; k < n; ++k)
            if (valid[j][k] && p_pair[i][j] < s[k] && s[k] <= nce[j]) ways[j][k] += ways[i][j];
    }
    std::int64_t count = 0;
    for (int i = 0; i < n; ++i) if (s[i] <= min_end && e[i] >= max_start) ++count;
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) if (e[j] >= max_start) count += ways[i][j];
    const auto bits = static_cast<std::uint64_t>(count);
    for (unsigned b = 0; b < 8; ++b) output[b] = static_cast<std::uint8_t>(bits >> (8 * b));
    return 8;
}
