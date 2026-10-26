#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 120, MaxInput = 2 + 3 * MaxM;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t max_cut_sahni_gonzalez(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || length != 2 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<std::int64_t, MaxN>, MaxN> weights{};
    std::array<std::array<bool, MaxN>, MaxN> seen{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 0 || weight > 10000) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        weights[u][v] = weights[v][u] = weight;
    }
    const auto outputBytes = 8 * (n + 1);
    if (!output || capacity < outputBytes) return -2;
    std::array<std::int64_t, MaxN> side{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::int64_t putZero = 0, putOne = 0;
        for (std::size_t prior = 0; prior < vertex; ++prior) {
            if (side[prior] == 1) putZero += weights[prior][vertex];
            else putOne += weights[prior][vertex];
        }
        side[vertex] = putOne > putZero ? 1 : 0;
    }
    std::int64_t cut = 0;
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = u + 1; v < n; ++v)
            if (side[u] != side[v]) cut += weights[u][v];
    storeI64LE(output, 0, cut);
    for (std::size_t vertex = 0; vertex < n; ++vertex) storeI64LE(output, 8 * (vertex + 1), side[vertex]);
    return static_cast<std::int64_t>(outputBytes);
}
