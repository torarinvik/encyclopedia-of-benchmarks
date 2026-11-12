#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 6;
constexpr std::size_t MaxEdges = 10;
constexpr std::size_t MaxAdjacencyPerVertex = 20;
constexpr std::size_t MaxOutputValues = 13;
constexpr std::size_t MaxOutputBytes = 104;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxEdges;

struct GraphContext {
    std::size_t vertex_count{}, edge_count{};
    std::array<std::size_t, MaxEdges> edge_left{}, edge_right{};
    std::array<std::size_t, MaxVertices> degree{};
    std::array<std::array<std::size_t, MaxAdjacencyPerVertex>, MaxVertices> adjacent_vertex{}, adjacent_edge{};
    std::array<std::int64_t, MaxVertices> discovery{}, low{};
    std::array<bool, MaxEdges> is_bridge{};
    std::size_t clock{};
    std::array<std::int64_t, MaxVertices> component{};
    std::array<std::array<std::size_t, MaxVertices>, MaxVertices> block_vertices{};
    std::array<std::size_t, MaxVertices> block_size{};
    std::size_t block_count{};
};

void find_bridges(GraphContext& context, std::size_t vertex, std::size_t parent_edge) {
    context.discovery[vertex] = context.low[vertex] = static_cast<std::int64_t>(context.clock++);
    for (std::size_t slot = 0; slot < context.degree[vertex]; ++slot) {
        const auto neighbor = context.adjacent_vertex[vertex][slot];
        const auto edge = context.adjacent_edge[vertex][slot];
        if (edge == parent_edge) continue;
        if (context.discovery[neighbor] < 0) {
            find_bridges(context, neighbor, edge);
            context.low[vertex] = std::min(context.low[vertex], context.low[neighbor]);
            if (context.low[neighbor] > context.discovery[vertex]) context.is_bridge[edge] = true;
        } else if (context.discovery[neighbor] < context.low[vertex]) {
            context.low[vertex] = context.discovery[neighbor];
        }
    }
}

void assign_components(GraphContext& context) {
    std::array<std::size_t, MaxVertices> queue{};
    for (std::size_t root = 0; root < context.vertex_count; ++root) {
        if (context.component[root] >= 0) continue;
        const auto block = context.block_count++;
        std::size_t head = 0, tail = 0;
        context.component[root] = static_cast<std::int64_t>(block);
        queue[tail++] = root;
        while (head < tail) {
            const auto vertex = queue[head++];
            for (std::size_t slot = 0; slot < context.degree[vertex]; ++slot) {
                const auto neighbor = context.adjacent_vertex[vertex][slot];
                const auto edge = context.adjacent_edge[vertex][slot];
                if (context.is_bridge[edge] || context.component[neighbor] >= 0) continue;
                context.component[neighbor] = static_cast<std::int64_t>(block);
                queue[tail++] = neighbor;
            }
        }
        for (std::size_t vertex = 0; vertex < context.vertex_count; ++vertex)
            if (context.component[vertex] == static_cast<std::int64_t>(block))
                context.block_vertices[block][context.block_size[block]++] = vertex;
    }
}

bool block_less(const GraphContext& context, std::size_t left, std::size_t right) {
    const auto common = std::min(context.block_size[left], context.block_size[right]);
    for (std::size_t i = 0; i < common; ++i) {
        if (context.block_vertices[left][i] != context.block_vertices[right][i])
            return context.block_vertices[left][i] < context.block_vertices[right][i];
    }
    return context.block_size[left] < context.block_size[right];
}

void store_u64_le(std::uint8_t* output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
} // namespace

extern "C" std::int64_t two_edge_connected_components(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > MaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxVertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MaxEdges)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    GraphContext context{};
    context.vertex_count = vertex_count;
    context.edge_count = edge_count;
    context.discovery.fill(-1);
    context.component.fill(-1);
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[2 + 2 * edge];
        const auto right = input[3 + 2 * edge];
        if (left < 0 || left >= static_cast<std::int64_t>(vertex_count) ||
            right < 0 || right >= static_cast<std::int64_t>(vertex_count)) return -1;
        const auto u = static_cast<std::size_t>(left), v = static_cast<std::size_t>(right);
        context.edge_left[edge] = u;
        context.edge_right[edge] = v;
        const auto u_slot = context.degree[u]++;
        const auto v_slot = context.degree[v]++;
        context.adjacent_vertex[u][u_slot] = v;
        context.adjacent_edge[u][u_slot] = edge;
        context.adjacent_vertex[v][v_slot] = u;
        context.adjacent_edge[v][v_slot] = edge;
    }
    for (std::size_t root = 0; root < vertex_count; ++root)
        if (context.discovery[root] < 0) find_bridges(context, root, MaxEdges);
    assign_components(context);

    std::array<std::size_t, MaxVertices> order{};
    for (std::size_t i = 0; i < context.block_count; ++i) {
        auto position = i;
        order[i] = i;
        while (position > 0 && block_less(context, order[position], order[position - 1])) {
            std::swap(order[position], order[position - 1]);
            --position;
        }
    }
    std::array<std::uint64_t, MaxOutputValues> packed{};
    std::size_t packed_count = 0;
    packed[packed_count++] = context.block_count;
    for (std::size_t i = 0; i < context.block_count; ++i) {
        const auto block = order[i];
        packed[packed_count++] = context.block_size[block];
        for (std::size_t j = 0; j < context.block_size[block]; ++j)
            packed[packed_count++] = context.block_vertices[block][j];
    }
    const auto bytes = 8 * packed_count;
    if (output == nullptr || output_capacity < bytes) return -2;
    std::array<std::uint8_t, MaxOutputBytes> staged{};
    for (std::size_t i = 0; i < packed_count; ++i) store_u64_le(staged.data(), 8 * i, packed[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
