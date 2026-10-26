// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 130;
constexpr int MaxColor = 128;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gardenia_gm_vertex_coloring(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    std::array<std::uint8_t, MaxN * MaxN> adjacent{};
    for (int e = 0; e < m; ++e) {
        const auto u64 = input[2 + 2 * static_cast<std::size_t>(e)];
        const auto v64 = input[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u * MaxN + v]) return -1;
        adjacent[u * MaxN + v] = adjacent[v * MaxN + u] = 1;
    }
    const auto outputBytes = 8 * static_cast<std::size_t>(n);
    if (!output || capacity < outputBytes) return -2;
    std::array<int, MaxN> colors{}, prior{}, pending{}, nextPending{};
    int pendingCount = n;
    for (int u = 0; u < n; ++u) { colors[u] = MaxColor; pending[u] = u; }
    int rounds = 0;
    while (pendingCount > 0) {
        if (++rounds > n + 1) return -1;
        prior = colors;
        for (int item = 0; item < pendingCount; ++item) {
            const int u = pending[item];
            std::array<bool, MaxN> forbidden{};
            for (int v = 0; v < n; ++v)
                if (adjacent[static_cast<std::size_t>(u) * MaxN + v] && prior[v] != MaxColor)
                    forbidden[static_cast<std::size_t>(prior[v])] = true;
            int color = 0;
            while (color < MaxColor && forbidden[static_cast<std::size_t>(color)]) ++color;
            if (color >= MaxColor) return -1;
            colors[u] = color;
        }
        int nextCount = 0;
        for (int item = 0; item < pendingCount; ++item) {
            const int u = pending[item];
            bool conflict = false;
            for (int v = u + 1; v < n; ++v)
                if (adjacent[static_cast<std::size_t>(u) * MaxN + v] && colors[u] == colors[v]) {
                    conflict = true; break;
                }
            if (conflict) { colors[u] = MaxColor; nextPending[nextCount++] = u; }
        }
        pendingCount = nextCount;
        for (int item = 0; item < pendingCount; ++item) pending[item] = nextPending[item];
    }
    for (int u = 0; u < n; ++u) storeI64LE(output, 8 * static_cast<std::size_t>(u), colors[u]);
    return static_cast<std::int64_t>(outputBytes);
}
