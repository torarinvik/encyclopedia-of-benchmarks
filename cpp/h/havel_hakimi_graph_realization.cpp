#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kN = 8, kEdges = 28, kMaxInput = 10;
void store_i64(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[offset + i] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t havel_hakimi_graph_realization(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const auto nv = input[0];
    if (nv < 0 || nv > static_cast<std::int64_t>(kN)) return -1;
    const auto n = static_cast<std::size_t>(nv);
    if (length != n + 1) return -1;
    std::array<int, kN> residual{};
    std::array<bool, kN> active{};
    for (std::size_t v = 0; v < n; ++v) {
        const auto d = input[v + 1];
        if (d < 0 || d >= nv) return -1;
        residual[v] = static_cast<int>(d); active[v] = true;
    }
    std::array<std::array<int, 2>, kEdges> edges{};
    std::size_t edge_count = 0;
    bool graphical = true;
    while (graphical) {
        int hub = -1;
        for (std::size_t v = 0; v < n; ++v)
            if (active[v] && residual[v] > 0 && (hub < 0 || residual[v] > residual[hub] ||
                (residual[v] == residual[hub] && static_cast<int>(v) < hub))) hub = static_cast<int>(v);
        if (hub < 0) break;
        const int d = residual[hub]; residual[hub] = 0; active[hub] = false;
        std::array<int, kN> candidates{}; std::size_t count = 0;
        for (std::size_t v = 0; v < n; ++v) if (active[v]) candidates[count++] = static_cast<int>(v);
        for (std::size_t i = 1; i < count; ++i) {
            const int value = candidates[i]; std::size_t j = i;
            while (j && (residual[candidates[j - 1]] < residual[value] ||
                (residual[candidates[j - 1]] == residual[value] && candidates[j - 1] > value))) {
                candidates[j] = candidates[j - 1]; --j;
            }
            candidates[j] = value;
        }
        if (static_cast<std::size_t>(d) > count) { graphical = false; break; }
        for (int i = 0; i < d; ++i) {
            const int w = candidates[static_cast<std::size_t>(i)];
            if (residual[w] == 0) { graphical = false; break; }
            --residual[w]; edges[edge_count++] = {hub < w ? hub : w, hub < w ? w : hub};
        }
    }
    std::array<std::int64_t, 2 + 2 * kEdges> words{};
    std::size_t used = 0;
    if (graphical) {
        words[used++] = 1; words[used++] = static_cast<std::int64_t>(edge_count);
        for (std::size_t i = 0; i < edge_count; ++i) { words[used++] = edges[i][0]; words[used++] = edges[i][1]; }
    } else { words[used++] = 0; }
    if (output == nullptr || capacity < used * 8) return -2;
    for (std::size_t i = 0; i < used; ++i) store_i64(output, 8 * i, words[i]);
    return static_cast<std::int64_t>(used * 8);
}
