#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 12, MaxInput = 111;

void put(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t hypergraph_incidence_graph_encoding(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 8 || m64 < 0 || m64 > 12) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, MaxM>, MaxN> incidence{};
    std::size_t offset = 2;
    for (std::size_t edge = 0; edge < m; ++edge) {
        if (offset >= length) return -1;
        const auto size = input[offset++];
        if (size < 0 || size > n64 || static_cast<std::uint64_t>(size) > length - offset) return -1;
        for (std::int64_t item = 0; item < size; ++item) {
            const auto vertex64 = input[offset++];
            if (vertex64 < 0 || vertex64 >= n64) return -1;
            const auto vertex = static_cast<std::size_t>(vertex64);
            if (incidence[vertex][edge]) return -1;
            incidence[vertex][edge] = true;
        }
    }
    if (offset != length) return -1;

    std::size_t count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        for (std::size_t edge = 0; edge < m; ++edge)
            count += incidence[vertex][edge];
    const auto nodes = n + m;
    const auto bytes = 8 * (2 + nodes + 2 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(nodes));
    put(output, 8, static_cast<std::int64_t>(count));
    std::size_t word = 2;
    for (std::size_t vertex = 0; vertex < n; ++vertex) put(output, 8 * word++, 0);
    for (std::size_t edge = 0; edge < m; ++edge) put(output, 8 * word++, 1);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        for (std::size_t edge = 0; edge < m; ++edge)
            if (incidence[vertex][edge]) {
                put(output, 8 * word++, static_cast<std::int64_t>(vertex));
                put(output, 8 * word++, static_cast<std::int64_t>(n + edge));
            }
    return static_cast<std::int64_t>(bytes);
}
