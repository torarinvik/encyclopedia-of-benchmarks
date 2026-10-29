#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertexCount = 63;
constexpr std::size_t MaxEdgeCount = 2047;
constexpr std::size_t MaxInputLength = 3 + 2 * MaxEdgeCount;

std::size_t count_bits(std::uint64_t value)
{
    std::size_t count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}
}

extern "C" std::int64_t dominator_tree(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 3 || length > MaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxVertexCount) ||
        input[1] < 0 || input[1] >= input[0] || input[2] < 0 ||
        input[2] > static_cast<std::int64_t>(MaxEdgeCount)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto root = static_cast<std::size_t>(input[1]);
    const auto edge_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + 2 * edge_count) return -1;

    std::uint64_t outgoing[MaxVertexCount]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto from_value = input[3 + 2 * edge];
        const auto to_value = input[4 + 2 * edge];
        if (from_value < 0 || to_value < 0 ||
            from_value >= static_cast<std::int64_t>(vertex_count) ||
            to_value >= static_cast<std::int64_t>(vertex_count)) return -1;
        outgoing[static_cast<std::size_t>(from_value)] |= UINT64_C(1) << static_cast<std::size_t>(to_value);
    }

    std::uint64_t reachable = UINT64_C(1) << root;
    std::uint64_t frontier = reachable;
    while (frontier != 0) {
        std::uint64_t discovered = 0;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
            if ((frontier & (UINT64_C(1) << vertex)) != 0) discovered |= outgoing[vertex];
        discovered &= ~reachable;
        reachable |= discovered;
        frontier = discovered;
    }

    std::uint64_t dominators[MaxVertexCount]{};
    dominators[root] = UINT64_C(1) << root;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if ((reachable & (UINT64_C(1) << vertex)) != 0 && vertex != root)
            dominators[vertex] = reachable;

    bool changed;
    do {
        changed = false;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const auto vertex_bit = UINT64_C(1) << vertex;
            if ((reachable & vertex_bit) == 0 || vertex == root) continue;
            std::uint64_t common = reachable;
            for (std::size_t predecessor = 0; predecessor < vertex_count; ++predecessor)
                if ((reachable & (UINT64_C(1) << predecessor)) != 0 &&
                    (outgoing[predecessor] & vertex_bit) != 0)
                    common &= dominators[predecessor];
            const auto updated = common | vertex_bit;
            if (updated != dominators[vertex]) {
                dominators[vertex] = updated;
                changed = true;
            }
        }
    } while (changed);

    if (output == nullptr || output_capacity < vertex_count) return -2;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if ((reachable & (UINT64_C(1) << vertex)) == 0) {
            output[vertex] = UINT8_MAX;
        } else if (vertex == root) {
            output[vertex] = static_cast<std::uint8_t>(root);
        } else {
            const auto strict = dominators[vertex] & ~(UINT64_C(1) << vertex);
            std::size_t best = root;
            std::size_t best_depth = 0;
            for (std::size_t candidate = 0; candidate < vertex_count; ++candidate) {
                if ((strict & (UINT64_C(1) << candidate)) == 0) continue;
                const auto depth = count_bits(dominators[candidate]);
                if (depth > best_depth) {
                    best = candidate;
                    best_depth = depth;
                }
            }
            output[vertex] = static_cast<std::uint8_t>(best);
        }
    }
    return static_cast<std::int64_t>(vertex_count);
}
