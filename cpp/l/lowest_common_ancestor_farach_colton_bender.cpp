#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 256, max_queries = 1024, max_arcs = 510;
constexpr std::size_t max_euler = 2 * max_nodes - 1, max_micro = 4;
constexpr std::size_t shape_count = 8, max_blocks = 128, max_levels = 8;
using Micro = std::array<std::array<std::array<std::uint8_t, max_micro>, max_micro>, shape_count>;
using Macro = std::array<std::array<std::uint16_t, max_blocks>, max_levels>;

std::uint16_t shallower(std::uint16_t a, std::uint16_t b,
                        const std::array<std::uint16_t, max_euler>& depth) {
    if (depth[a] != depth[b]) return depth[a] < depth[b] ? a : b;
    return a < b ? a : b;
}

std::uint16_t range_minimum(std::uint16_t first, std::uint16_t last,
    std::size_t euler_count, std::size_t block_size,
    const std::array<std::uint16_t, max_euler>& depth,
    const std::array<std::uint8_t, max_blocks>& pattern, const Micro& micro,
    const Macro& macro, const std::array<std::uint8_t, max_blocks + 1>& logs) {
    const std::size_t ba = first / block_size, bb = last / block_size;
    const std::size_t oa = first % block_size, ob = last % block_size;
    if (ba == bb) return static_cast<std::uint16_t>(ba * block_size + micro[pattern[ba]][oa][ob]);
    const std::size_t base_a = ba * block_size, base_b = bb * block_size;
    const std::size_t len_a = euler_count - base_a < block_size ? euler_count - base_a : block_size;
    std::uint16_t best = static_cast<std::uint16_t>(base_a + micro[pattern[ba]][oa][len_a - 1]);
    best = shallower(best, static_cast<std::uint16_t>(base_b + micro[pattern[bb]][0][ob]), depth);
    if (bb > ba + 1) {
        const std::size_t lo = ba + 1, hi = bb - 1, count = hi - lo + 1;
        const std::size_t level = logs[count], span = std::size_t{1} << level;
        best = shallower(best, macro[level][lo], depth);
        best = shallower(best, macro[level][hi - span + 1], depth);
    }
    return best;
}
}

extern "C" std::int64_t lowest_common_ancestor_farach_colton_bender(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t output_capacity) noexcept {
    if (!input || length < 4 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] >= static_cast<std::int64_t>(n) || input[2] != static_cast<std::int64_t>(n - 1) ||
        input[3] < 0 || input[3] > static_cast<std::int64_t>(max_queries)) return -1;
    const std::size_t edge_count = static_cast<std::size_t>(input[2]);
    const std::size_t query_count = static_cast<std::size_t>(input[3]);
    const std::size_t query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const std::size_t root = static_cast<std::size_t>(input[1]);

    std::array<int, max_nodes> head{}, parent{}, tree_depth{}, first{};
    std::array<int, max_arcs> arc_to{}, arc_next{};
    std::array<std::uint16_t, max_euler> euler{}, euler_depth{};
    std::array<int, max_nodes> stack_node{}, stack_arc{};
    head.fill(-1); parent.fill(-2);
    std::size_t arcs = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u = input[4 + 2 * edge], v = input[5 + 2 * edge];
        if (u < 0 || u >= static_cast<std::int64_t>(n) || v < 0 || v >= static_cast<std::int64_t>(n) || u == v) return -1;
        const auto a = static_cast<std::size_t>(u), b = static_cast<std::size_t>(v);
        arc_to[arcs] = static_cast<int>(b); arc_next[arcs] = head[a]; head[a] = static_cast<int>(arcs++);
        arc_to[arcs] = static_cast<int>(a); arc_next[arcs] = head[b]; head[b] = static_cast<int>(arcs++);
    }
    for (std::size_t q = 0; q < query_count; ++q)
        for (std::size_t side = 0; side < 2; ++side) {
            const auto node = input[query_offset + 2 * q + side];
            if (node < 0 || node >= static_cast<std::int64_t>(n)) return -1;
        }

    std::size_t euler_count = 1, top = 1, reached = 1;
    parent[root] = -1; tree_depth[root] = 0; first[root] = 0;
    euler[0] = static_cast<std::uint16_t>(root); euler_depth[0] = 0;
    stack_node[0] = static_cast<int>(root); stack_arc[0] = head[root];
    while (top > 0) {
        const std::size_t slot = top - 1, node = static_cast<std::size_t>(stack_node[slot]);
        const int arc = stack_arc[slot];
        if (arc < 0) {
            --top;
            if (top > 0) {
                const auto up = static_cast<std::size_t>(stack_node[top - 1]);
                euler[euler_count] = static_cast<std::uint16_t>(up);
                euler_depth[euler_count++] = static_cast<std::uint16_t>(tree_depth[up]);
            }
            continue;
        }
        stack_arc[slot] = arc_next[static_cast<std::size_t>(arc)];
        const auto neighbor = static_cast<std::size_t>(arc_to[static_cast<std::size_t>(arc)]);
        if (static_cast<int>(neighbor) == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = static_cast<int>(node);
        tree_depth[neighbor] = tree_depth[node] + 1;
        first[neighbor] = static_cast<int>(euler_count);
        euler[euler_count] = static_cast<std::uint16_t>(neighbor);
        euler_depth[euler_count++] = static_cast<std::uint16_t>(tree_depth[neighbor]);
        ++reached;
        stack_node[top] = static_cast<int>(neighbor); stack_arc[top] = head[neighbor]; ++top;
    }
    if (reached != n) return -1;
    if (output_capacity < query_count || (query_count != 0 && !output)) return -2;

    std::size_t logarithm = 0;
    for (std::size_t x = euler_count; x > 1; x >>= 1) ++logarithm;
    const std::size_t block_size = logarithm / 2 == 0 ? 1 : logarithm / 2;
    const std::size_t block_count = (euler_count + block_size - 1) / block_size;
    Micro micro{};
    std::array<std::uint8_t, max_blocks> pattern{};
    std::array<std::uint8_t, max_blocks + 1> logs{};
    Macro macro{};
    const std::size_t shapes = std::size_t{1} << (block_size - 1);
    for (std::size_t shape = 0; shape < shapes; ++shape) {
        std::array<int, max_micro> relative{};
        for (std::size_t step = 0; step + 1 < block_size; ++step)
            relative[step + 1] = relative[step] + (((shape >> step) & 1) ? 1 : -1);
        for (std::size_t left = 0; left < block_size; ++left)
            for (std::size_t right = left; right < block_size; ++right) {
                std::size_t best = left;
                for (std::size_t at = left + 1; at <= right; ++at)
                    if (relative[at] < relative[best]) best = at;
                micro[shape][left][right] = static_cast<std::uint8_t>(best);
            }
    }
    for (std::size_t block = 0; block < block_count; ++block) {
        const std::size_t base = block * block_size;
        const std::size_t end = euler_count - base < block_size ? euler_count : base + block_size;
        auto best = static_cast<std::uint16_t>(base);
        for (std::size_t at = base; at + 1 < end; ++at) {
            if (euler_depth[at + 1] > euler_depth[at]) pattern[block] |= static_cast<std::uint8_t>(1u << (at - base));
            best = shallower(best, static_cast<std::uint16_t>(at + 1), euler_depth);
        }
        macro[0][block] = best;
    }
    for (std::size_t count = 2; count <= block_count; ++count) logs[count] = static_cast<std::uint8_t>(logs[count / 2] + 1);
    std::size_t macro_levels = 1;
    while ((std::size_t{1} << macro_levels) <= block_count && macro_levels < max_levels) {
        const std::size_t half = std::size_t{1} << (macro_levels - 1), span = 2 * half;
        for (std::size_t block = 0; block + span <= block_count; ++block)
            macro[macro_levels][block] = shallower(macro[macro_levels - 1][block], macro[macro_levels - 1][block + half], euler_depth);
        ++macro_levels;
    }
    std::array<std::uint8_t, max_queries> answers{};
    for (std::size_t q = 0; q < query_count; ++q) {
        const auto u = static_cast<std::size_t>(input[query_offset + 2 * q]);
        const auto v = static_cast<std::size_t>(input[query_offset + 2 * q + 1]);
        std::size_t left = static_cast<std::size_t>(first[u]), right = static_cast<std::size_t>(first[v]);
        if (left > right) { const auto temp = left; left = right; right = temp; }
        const auto at = range_minimum(static_cast<std::uint16_t>(left), static_cast<std::uint16_t>(right),
            euler_count, block_size, euler_depth, pattern, micro, macro, logs);
        answers[q] = static_cast<std::uint8_t>(euler[at]);
    }
    for (std::size_t q = 0; q < query_count; ++q) output[q] = answers[q];
    return static_cast<std::int64_t>(query_count);
}
