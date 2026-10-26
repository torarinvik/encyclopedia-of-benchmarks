#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 2 + MaxN + 2 * MaxM;
constexpr std::int64_t MaxPriority = 99'999'998;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t pannotia_local_minimum_mis(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) ||
        length != 2 + static_cast<std::size_t>(n64) + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::uint64_t, MaxN> adjacency{};
    std::array<std::int64_t, MaxN> priority{};
    for (std::size_t v = 0; v < n; ++v) {
        priority[v] = input[2 + v];
        if (priority[v] < 0 || priority[v] > MaxPriority) return -1;
        for (std::size_t prior = 0; prior < v; ++prior)
            if (priority[prior] == priority[v]) return -1;
    }
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + n + 2 * edge], v64 = input[3 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacency[u] & (UINT64_C(1) << v)) return -1;
        adjacency[u] |= UINT64_C(1) << v;
        adjacency[v] |= UINT64_C(1) << u;
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;
    std::array<bool, MaxN> active{}, selected{};
    for (std::size_t v = 0; v < n; ++v) active[v] = true;
    for (;;) {
        std::array<bool, MaxN> chosen{};
        std::size_t chosenCount = 0;
        for (std::size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            bool localMinimum = true;
            for (std::size_t u = 0; u < n; ++u)
                if (active[u] && (adjacency[v] & (UINT64_C(1) << u)) && priority[u] < priority[v]) localMinimum = false;
            if (localMinimum) { chosen[v] = true; ++chosenCount; }
        }
        if (chosenCount == 0) return -1;
        for (std::size_t v = 0; v < n; ++v) if (chosen[v]) { selected[v] = true; active[v] = false; }
        for (std::size_t v = 0; v < n; ++v) if (chosen[v])
            for (std::size_t u = 0; u < n; ++u)
                if (active[u] && (adjacency[v] & (UINT64_C(1) << u))) active[u] = false;
        bool remaining = false;
        for (std::size_t v = 0; v < n; ++v) remaining = remaining || active[v];
        if (!remaining) break;
    }
    for (std::size_t v = 0; v < n; ++v) storeI64LE(output, 8 * v, selected[v] ? 2 : 0);
    return static_cast<std::int64_t>(outputBytes);
}
