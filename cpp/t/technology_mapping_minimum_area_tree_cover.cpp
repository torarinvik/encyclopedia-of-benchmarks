#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t MaxN = 31, MaxOutput = 256;
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[offset + b] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t technology_mapping_minimum_area_tree_cover(const std::int64_t *v, std::size_t length,
                                                                    std::uint8_t *output, std::size_t capacity) {
    if (v == nullptr || length < 9 || length > 99 || v[0] < 1 || v[0] > 31) return -1;
    const auto n = static_cast<std::size_t>(v[0]); if (length != 6 + 3 * n) return -1;
    std::int64_t costs[5];
    for (std::size_t p = 0; p < 5; ++p) { costs[p] = v[1 + p]; if (costs[p] != -1 && (costs[p] < 1 || costs[p] > 1000000)) return -1; }
    int kind[MaxN], left[MaxN], right[MaxN], parents[MaxN]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto at = 6 + 3 * i; const auto k = v[at], l = v[at + 1], r = v[at + 2];
        if (k < 0 || k > 2) return -1; kind[i] = static_cast<int>(k); left[i] = static_cast<int>(l); right[i] = static_cast<int>(r);
        if (k == 0) { if (l != -1 || r != -1) return -1; }
        else if (k == 1) { if (l <= static_cast<std::int64_t>(i) || l >= static_cast<std::int64_t>(n) || r != -1) return -1; ++parents[l]; }
        else { if (l <= static_cast<std::int64_t>(i) || l >= static_cast<std::int64_t>(n) || r <= static_cast<std::int64_t>(i) || r >= static_cast<std::int64_t>(n) || l == r) return -1; ++parents[l]; ++parents[r]; }
    }
    if (parents[0] != 0) return -1; for (std::size_t i = 1; i < n; ++i) if (parents[i] != 1) return -1;
    constexpr std::int64_t Inf = INT64_MAX / 4; std::int64_t best[MaxN]; int choice[MaxN];
    for (std::size_t i = n; i-- > 0;) {
        best[i] = Inf; choice[i] = -1; if (kind[i] == 0) { best[i] = 0; continue; }
        auto consider = [&](int pattern, std::int64_t value) { if (costs[pattern] >= 0 && value < Inf && value < best[i]) { best[i] = value; choice[i] = pattern; } };
        if (kind[i] == 1) consider(0, costs[0] + best[left[i]]);
        else { consider(1, costs[1] + best[left[i]] + best[right[i]]);
            if (kind[left[i]] == 1) consider(2, costs[2] + best[left[left[i]]] + best[right[i]]);
            if (kind[right[i]] == 1) consider(3, costs[3] + best[left[i]] + best[left[right[i]]]);
            if (kind[left[i]] == 1 && kind[right[i]] == 1) consider(4, costs[4] + best[left[left[i]]] + best[left[right[i]]]); }
    }
    if (best[0] == Inf) return -1;
    int mapping[MaxN]; for (std::size_t i = 0; i < n; ++i) mapping[i] = kind[i] == 0 ? -1 : -3;
    int stack[2 * MaxN], top = 0; if (kind[0] != 0) stack[top++] = 0;
    while (top > 0) { const int node = stack[--top], p = choice[node]; mapping[node] = p;
        if (p == 0) stack[top++] = left[node]; else if (p == 1) { stack[top++] = left[node]; stack[top++] = right[node]; }
        else if (p == 2) { mapping[left[node]] = -2; stack[top++] = left[left[node]]; stack[top++] = right[node]; }
        else if (p == 3) { mapping[right[node]] = -2; stack[top++] = left[node]; stack[top++] = left[right[node]]; }
        else { mapping[left[node]] = -2; mapping[right[node]] = -2; stack[top++] = left[left[node]]; stack[top++] = left[right[node]]; }
    }
    const auto bytes = 8 * (n + 1); if (output == nullptr || capacity < bytes) return -2;
    std::uint8_t staged[MaxOutput]{}; put_i64(staged, 0, best[0]); for (std::size_t i = 0; i < n; ++i) put_i64(staged, 8 * (i + 1), mapping[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i]; return static_cast<std::int64_t>(bytes);
}
