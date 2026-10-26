#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 3 + MaxN + 2 * MaxM;
constexpr std::int64_t MaxPriority = 99'999'998;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t pannotia_priority_coloring(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], mode64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || (mode64 != 0 && mode64 != 1) ||
        length != 3 + static_cast<std::size_t>(n64) + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const int mode = static_cast<int>(mode64);
    std::array<std::uint64_t, MaxN> adjacency{};
    std::array<std::size_t, MaxN> degree{};
    std::array<std::int64_t, MaxN> priority{}, color{};
    std::array<bool, MaxN> active{};
    for (std::size_t v = 0; v < n; ++v) {
        priority[v] = input[3 + v];
        if (priority[v] < 0 || priority[v] > MaxPriority) return -1;
        for (std::size_t prior = 0; prior < v; ++prior)
            if (priority[prior] == priority[v]) return -1;
        color[v] = -1;
        active[v] = true;
    }
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[3 + n + 2 * edge], v64 = input[4 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacency[u] & (UINT64_C(1) << v)) return -1;
        adjacency[u] |= UINT64_C(1) << v;
        adjacency[v] |= UINT64_C(1) << u;
        ++degree[u]; ++degree[v];
    }
    for (std::size_t v = 0; v < n; ++v) if (degree[v] == 1) return -1;
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;
    std::int64_t currentColor = 1;
    for (;;) {
        std::array<bool, MaxN> chosen{};
        std::size_t chosenCount = 0;
        for (std::size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            std::int64_t maximum = -1, minimum = 99'999'999;
            for (std::size_t u = 0; u < n; ++u) if (active[u] && (adjacency[v] & (UINT64_C(1) << u))) {
                if (priority[u] > maximum) maximum = priority[u];
                if (priority[u] < minimum) minimum = priority[u];
            }
            if (priority[v] > maximum) { color[v] = currentColor; chosen[v] = true; }
            if (mode == 1 && priority[v] < minimum) { color[v] = currentColor + 1; chosen[v] = true; }
            if (chosen[v]) ++chosenCount;
        }
        if (chosenCount == 0) return -1;
        for (std::size_t v = 0; v < n; ++v) if (chosen[v]) active[v] = false;
        bool remaining = false;
        for (std::size_t v = 0; v < n; ++v) remaining = remaining || active[v];
        if (!remaining) break;
        currentColor += mode == 1 ? 2 : 1;
    }
    for (std::size_t v = 0; v < n; ++v) storeI64LE(output, 8 * v, color[v]);
    return static_cast<std::int64_t>(outputBytes);
}
