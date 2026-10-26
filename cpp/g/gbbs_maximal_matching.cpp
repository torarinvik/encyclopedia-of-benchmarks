#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 2 + 3 * MaxM;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_maximal_matching(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) ||
        length != 2 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto m = static_cast<std::size_t>(m64);
    std::array<bool, MaxM> rankSeen{};
    std::array<std::size_t, MaxM> order{};
    std::array<std::array<bool, MaxN>, MaxN> adjacency{};
    const auto edgeStart = 2 + m;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto rank64 = input[2 + edge];
        if (rank64 < 0 || rank64 >= m64 || rankSeen[static_cast<std::size_t>(rank64)]) return -1;
        const auto rank = static_cast<std::size_t>(rank64);
        rankSeen[rank] = true;
        order[rank] = edge;
        const auto u64 = input[edgeStart + 2 * edge], v64 = input[edgeStart + 2 * edge + 1];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = true;
    }
    const auto outputBytes = 8 * m;
    if (!output || capacity < outputBytes) return -2;
    std::array<bool, MaxN> matched{};
    std::array<std::int64_t, MaxM> selected{};
    for (std::size_t rank = 0; rank < m; ++rank) {
        const auto edge = order[rank];
        const auto u = static_cast<std::size_t>(input[edgeStart + 2 * edge]);
        const auto v = static_cast<std::size_t>(input[edgeStart + 2 * edge + 1]);
        if (!matched[u] && !matched[v]) {
            selected[edge] = 1;
            matched[u] = matched[v] = true;
        }
    }
    for (std::size_t edge = 0; edge < m; ++edge) storeI64LE(output, 8 * edge, selected[edge]);
    return static_cast<std::int64_t>(outputBytes);
}
