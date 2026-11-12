#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 8;
constexpr std::size_t MaxEdges = 12;
constexpr std::size_t MaxInputLength = 26;
constexpr std::size_t MaxOutputBytes = 96;
} // namespace

extern "C" std::int64_t counting_c4(const std::int64_t* values, std::size_t length,
                                    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > MaxInputLength) return -1;
    const auto n_value = values[0];
    const auto m_value = values[1];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(MaxVertices) ||
        m_value < 1 || m_value > static_cast<std::int64_t>(MaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto edge_count = static_cast<std::size_t>(m_value);
    if (length != 2 + 2 * edge_count) return -1;

    std::array<std::array<std::int64_t, MaxVertices>, MaxVertices> multiplicity{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u_value = values[2 + 2 * edge];
        const auto v_value = values[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        ++multiplicity[u][v];
        ++multiplicity[v][u];
    }

    std::array<std::uint64_t, MaxEdges> answers{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u = static_cast<std::size_t>(values[2 + 2 * edge]);
        const auto v = static_cast<std::size_t>(values[3 + 2 * edge]);
        for (std::size_t a = 0; a < n; ++a) {
            if (a == u || a == v) continue;
            for (std::size_t b = 0; b < n; ++b) {
                if (b == u || b == v || b == a) continue;
                answers[edge] += static_cast<std::uint64_t>(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v]);
            }
        }
    }

    const auto bytes = 8 * edge_count;
    if (output == nullptr || output_capacity < bytes) return -2;
    std::array<std::uint8_t, MaxOutputBytes> staged{};
    for (std::size_t edge = 0; edge < edge_count; ++edge)
        for (std::size_t byte = 0; byte < 8; ++byte)
            staged[8 * edge + byte] = static_cast<std::uint8_t>(answers[edge] >> (8 * byte));
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
