#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSideVertices = 5;
constexpr std::size_t MaxEdges = 10;
constexpr std::size_t MaxInputLength = 23;
constexpr std::size_t MaxOutputBytes = 88;
using Matrix = std::array<std::array<std::int64_t, MaxSideVertices>, MaxSideVertices>;

bool augment_matching(std::size_t left, std::size_t side, const Matrix& multiplicity,
                     std::array<bool, MaxSideVertices>& seen,
                     std::array<int, MaxSideVertices>& match_right) {
    for (std::size_t right = 0; right < side; ++right) {
        if (multiplicity[left][right] == 0 || seen[right]) continue;
        seen[right] = true;
        if (match_right[right] < 0 || augment_matching(static_cast<std::size_t>(match_right[right]),
                                                       side, multiplicity, seen, match_right)) {
            match_right[right] = static_cast<int>(left);
            return true;
        }
    }
    return false;
}
} // namespace

extern "C" std::int64_t bipartite_edge_coloring(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 3 || length > MaxInputLength) return -1;
    const auto left_value = values[0];
    const auto right_value = values[1];
    const auto edge_value = values[2];
    if (left_value < 1 || left_value > static_cast<std::int64_t>(MaxSideVertices) ||
        right_value < 1 || right_value > static_cast<std::int64_t>(MaxSideVertices) ||
        edge_value < 1 || edge_value > static_cast<std::int64_t>(MaxEdges)) return -1;
    const auto left_count = static_cast<std::size_t>(left_value);
    const auto right_count = static_cast<std::size_t>(right_value);
    const auto edge_count = static_cast<std::size_t>(edge_value);
    if (length != 3 + 2 * edge_count) return -1;

    Matrix multiplicity{};
    Matrix original_remaining{};
    std::array<std::size_t, MaxSideVertices> left_degree{};
    std::array<std::size_t, MaxSideVertices> right_degree{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = values[3 + 2 * edge];
        const auto right = values[4 + 2 * edge];
        if (left < 0 || left >= left_value || right < 0 || right >= right_value) return -1;
        ++multiplicity[static_cast<std::size_t>(left)][static_cast<std::size_t>(right)];
        ++original_remaining[static_cast<std::size_t>(left)][static_cast<std::size_t>(right)];
        ++left_degree[static_cast<std::size_t>(left)];
        ++right_degree[static_cast<std::size_t>(right)];
    }

    const auto side = left_count > right_count ? left_count : right_count;
    std::size_t maximum_degree = 0;
    for (std::size_t vertex = 0; vertex < side; ++vertex) {
        if (left_degree[vertex] > maximum_degree) maximum_degree = left_degree[vertex];
        if (right_degree[vertex] > maximum_degree) maximum_degree = right_degree[vertex];
    }
    for (;;) {
        std::size_t left = 0;
        while (left < side && left_degree[left] == maximum_degree) ++left;
        if (left == side) break;
        std::size_t right = 0;
        while (right < side && right_degree[right] == maximum_degree) ++right;
        if (right == side) return -1;
        ++multiplicity[left][right];
        ++left_degree[left];
        ++right_degree[right];
    }

    std::array<std::int64_t, MaxEdges> colors{};
    colors.fill(-1);
    for (std::size_t color = 0; color < maximum_degree; ++color) {
        std::array<int, MaxSideVertices> match_right{};
        match_right.fill(-1);
        for (std::size_t left = 0; left < side; ++left) {
            std::array<bool, MaxSideVertices> seen{};
            if (!augment_matching(left, side, multiplicity, seen, match_right)) return -1;
        }
        for (std::size_t right = 0; right < side; ++right) {
            const auto left = static_cast<std::size_t>(match_right[right]);
            if (original_remaining[left][right] > 0) {
                std::size_t edge = 0;
                while (edge < edge_count &&
                       (colors[edge] >= 0 || values[3 + 2 * edge] != static_cast<std::int64_t>(left) ||
                        values[4 + 2 * edge] != static_cast<std::int64_t>(right))) ++edge;
                if (edge == edge_count) return -1;
                colors[edge] = static_cast<std::int64_t>(color);
                --original_remaining[left][right];
            }
            --multiplicity[left][right];
        }
    }

    const auto bytes = 8 * (edge_count + 1);
    if (output == nullptr || output_capacity < bytes) return -2;
    std::array<std::uint8_t, MaxOutputBytes> staged{};
    const auto color_count = static_cast<std::uint64_t>(maximum_degree);
    for (std::size_t byte = 0; byte < 8; ++byte)
        staged[byte] = static_cast<std::uint8_t>(color_count >> (8 * byte));
    for (std::size_t edge = 0; edge < edge_count; ++edge)
        for (std::size_t byte = 0; byte < 8; ++byte)
            staged[8 * (edge + 1) + byte] = static_cast<std::uint8_t>(static_cast<std::uint64_t>(colors[edge]) >> (8 * byte));
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
