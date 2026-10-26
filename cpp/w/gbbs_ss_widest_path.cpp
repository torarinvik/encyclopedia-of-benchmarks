// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 3 + 3 * MaxM;
constexpr std::int64_t SourceInfinity = INT64_C(2147483647);
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_ss_widest_path(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 || m64 > static_cast<std::int64_t>(MaxM) ||
        source64 < 0 || source64 >= n64 || length != 3 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64), source = static_cast<std::size_t>(source64);
    std::array<int, MaxM> edgeFrom{}, edgeTo{}, edgeCapacity{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto from = input[3 + 3 * edge], to = input[4 + 3 * edge], edgeWidth = input[5 + 3 * edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || edgeWidth < 1 || edgeWidth > 32) return -1;
        edgeFrom[edge] = static_cast<int>(from);
        edgeTo[edge] = static_cast<int>(to);
        edgeCapacity[edge] = static_cast<int>(edgeWidth);
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;

    std::array<std::int64_t, MaxN> width{};
    std::array<bool, MaxN> settled{};
    width[source] = SourceInfinity;
    for (std::size_t step = 0; step < n; ++step) {
        std::size_t u = n;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (!settled[vertex] && (u == n || width[vertex] > width[u])) u = vertex;
        if (u == n || width[u] == 0) break;
        settled[u] = true;
        for (std::size_t edge = 0; edge < m; ++edge) {
            if (edgeFrom[edge] != static_cast<int>(u)) continue;
            const auto v = static_cast<std::size_t>(edgeTo[edge]);
            if (settled[v]) continue;
            const auto candidate = width[u] < edgeCapacity[edge] ? width[u] : edgeCapacity[edge];
            if (candidate > width[v]) width[v] = candidate;
        }
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) storeI64LE(output, 8 * vertex, width[vertex]);
    return static_cast<std::int64_t>(outputBytes);
}
