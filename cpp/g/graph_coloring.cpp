#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 8;
constexpr std::size_t max_colors = 4;
constexpr std::size_t max_validation_length = 11;
constexpr std::int64_t output_bytes = 8;

std::int64_t count_from(const std::array<std::uint8_t, max_vertices>& masks,
                        std::array<std::uint8_t, max_vertices> colors,
                        std::size_t vertex_count, std::size_t color_count,
                        std::size_t vertex) {
    if (vertex == vertex_count) return 1;
    std::int64_t count = 0;
    for (std::size_t color = 0; color < color_count; ++color) {
        bool safe = true;
        for (std::size_t prior = 0; prior < vertex; ++prior) {
            if ((masks[vertex] & static_cast<std::uint8_t>(1U << prior)) != 0 && colors[prior] == color) {
                safe = false;
                break;
            }
        }
        if (safe) {
            colors[vertex] = static_cast<std::uint8_t>(color);
            count += count_from(masks, colors, vertex_count, color_count, vertex + 1);
        }
    }
    return count;
}

void put_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t graph_coloring(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_validation_length) return -1;
    const std::int64_t n64 = input[0];
    const std::int64_t m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_vertices) ||
        m64 < 1 || m64 > static_cast<std::int64_t>(max_colors)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    if (length != n + 2) return -1;

    std::array<std::uint8_t, max_vertices> masks{};
    const std::uint64_t mask_limit = UINT64_C(1) << n;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        if (input[2 + vertex] < 0 || static_cast<std::uint64_t>(input[2 + vertex]) >= mask_limit) return -1;
        masks[vertex] = static_cast<std::uint8_t>(input[2 + vertex]);
        if ((masks[vertex] & static_cast<std::uint8_t>(1U << vertex)) != 0) return -1;
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            const bool edge = (masks[vertex] & static_cast<std::uint8_t>(1U << neighbor)) != 0;
            const bool reverse_edge = (masks[neighbor] & static_cast<std::uint8_t>(1U << vertex)) != 0;
            if (edge != reverse_edge) return -1;
        }
    }
    if (output == nullptr || capacity < static_cast<std::size_t>(output_bytes)) return -2;
    std::array<std::uint8_t, max_vertices> colors{};
    const auto count = count_from(masks, colors, n, m, 0);
    put_i64_le(output, count);
    return output_bytes;
}
