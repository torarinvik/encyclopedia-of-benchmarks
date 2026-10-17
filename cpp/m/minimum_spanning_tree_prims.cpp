#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_edges = 64;
constexpr std::size_t max_parseable_input_length = 2 + 3 * max_edges + 1;
constexpr std::size_t max_output_words = 1 + 2 * (max_vertices - 1);
constexpr std::size_t max_output_bytes = 4 * max_output_words;
constexpr std::int64_t source_heap_sentinel = INT64_MAX;

void top_to_bottom(std::array<std::int64_t, max_vertices>& heap,
                   std::array<std::int32_t, max_vertices>& positions,
                   std::array<std::int32_t, max_vertices>& node_position,
                   std::size_t size, std::size_t start) {
    std::size_t root = start;
    while (root * 2 + 1 < size) {
        const std::size_t left = root * 2 + 1;
        const std::size_t right = left + 1;
        const std::size_t child = right >= size || heap[left] < heap[right] ? left : right;
        if (heap[child] >= heap[root]) break;
        const auto heap_value = heap[root];
        heap[root] = heap[child];
        heap[child] = heap_value;
        const auto vertex = positions[root];
        positions[root] = positions[child];
        positions[child] = vertex;
        node_position[static_cast<std::size_t>(positions[root])] = static_cast<std::int32_t>(root);
        node_position[static_cast<std::size_t>(positions[child])] = static_cast<std::int32_t>(child);
        root = child;
    }
}

void decrease_key(std::int64_t value, std::size_t index,
                  std::array<std::int64_t, max_vertices>& heap,
                  std::array<std::int32_t, max_vertices>& positions,
                  std::array<std::int32_t, max_vertices>& node_position) {
    const auto vertex = positions[index];
    while (index != 0) {
        const std::size_t parent = (index - 1) / 2;
        if (value < heap[parent]) {
            heap[index] = heap[parent];
            positions[index] = positions[parent];
            node_position[static_cast<std::size_t>(positions[parent])] = static_cast<std::int32_t>(index);
        } else {
            heap[index] = value;
            positions[index] = vertex;
            node_position[static_cast<std::size_t>(vertex)] = static_cast<std::int32_t>(index);
            return;
        }
        index = parent;
    }
    heap[0] = value;
    positions[0] = vertex;
    node_position[static_cast<std::size_t>(vertex)] = 0;
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t minimum_spanning_tree_prims(
    const std::int32_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto raw_vertices = input[0];
    const auto raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > static_cast<std::int32_t>(max_vertices) ||
        raw_edges < 0 || raw_edges > static_cast<std::int32_t>(max_edges)) return -1;
    const auto vertex_count = static_cast<std::size_t>(raw_vertices);
    const auto edge_count = static_cast<std::size_t>(raw_edges);
    if (length != 2 + 3 * edge_count) return -1;

    std::array<std::array<std::int32_t, max_vertices>, max_vertices> neighbors{};
    std::array<std::array<std::int32_t, max_vertices>, max_vertices> weights{};
    std::array<std::int32_t, max_vertices> degree{};
    std::array<std::array<bool, max_vertices>, max_vertices> seen{};
    for (std::size_t index = 0; index < edge_count; ++index) {
        const auto offset = 2 + 3 * index;
        const auto u = input[offset];
        const auto v = input[offset + 1];
        const auto weight = input[offset + 2];
        if (u < 0 || v <= u || v >= raw_vertices || seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)])
            return -1;
        seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = true;
        const auto u_degree = degree[static_cast<std::size_t>(u)]++;
        neighbors[static_cast<std::size_t>(u)][static_cast<std::size_t>(u_degree)] = v;
        weights[static_cast<std::size_t>(u)][static_cast<std::size_t>(u_degree)] = weight;
        const auto v_degree = degree[static_cast<std::size_t>(v)]++;
        neighbors[static_cast<std::size_t>(v)][static_cast<std::size_t>(v_degree)] = u;
        weights[static_cast<std::size_t>(v)][static_cast<std::size_t>(v_degree)] = weight;
    }

    if (vertex_count > 1) {
        std::array<bool, max_vertices> reached_vertex{};
        std::array<std::int32_t, max_vertices> stack{};
        std::size_t stack_size = 1, reached = 0;
        stack[0] = 0;
        reached_vertex[0] = true;
        while (stack_size > 0) {
            const auto vertex = stack[--stack_size];
            ++reached;
            for (std::int32_t i = 0; i < degree[static_cast<std::size_t>(vertex)]; ++i) {
                const auto neighbor = neighbors[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(i)];
                if (!reached_vertex[static_cast<std::size_t>(neighbor)]) {
                    reached_vertex[static_cast<std::size_t>(neighbor)] = true;
                    stack[stack_size++] = neighbor;
                }
            }
        }
        if (reached != vertex_count) return -1;
    }

    std::array<bool, max_vertices> visited{};
    std::array<std::int32_t, max_vertices> parent{};
    std::array<std::int64_t, max_vertices> heap{};
    std::array<std::int32_t, max_vertices> positions{}, node_position{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        parent[vertex] = -1;
        heap[vertex] = source_heap_sentinel;
        positions[vertex] = static_cast<std::int32_t>(vertex);
        node_position[vertex] = static_cast<std::int32_t>(vertex);
    }
    visited[0] = true;
    for (std::int32_t i = 0; i < degree[0]; ++i) {
        const auto neighbor = neighbors[0][static_cast<std::size_t>(i)];
        parent[static_cast<std::size_t>(neighbor)] = 0;
        heap[static_cast<std::size_t>(neighbor)] = weights[0][static_cast<std::size_t>(i)];
    }
    for (std::size_t start = vertex_count / 2; start > 0; --start)
        top_to_bottom(heap, positions, node_position, vertex_count, start - 1);

    std::array<std::int32_t, max_output_words> words{};
    std::size_t word_count = 1, tree_edge_count = 0;
    for (std::size_t step = 1; step < vertex_count; ++step) {
        const auto vertex = positions[0];
        heap[0] = source_heap_sentinel;
        top_to_bottom(heap, positions, node_position, vertex_count, 0);
        if (!visited[static_cast<std::size_t>(vertex)]) {
            words[word_count++] = parent[static_cast<std::size_t>(vertex)];
            words[word_count++] = vertex;
            ++tree_edge_count;
            visited[static_cast<std::size_t>(vertex)] = true;
            for (std::int32_t i = 0; i < degree[static_cast<std::size_t>(vertex)]; ++i) {
                const auto neighbor = neighbors[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(i)];
                const auto weight = weights[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(i)];
                if (!visited[static_cast<std::size_t>(neighbor)]) {
                    const auto heap_index = static_cast<std::size_t>(node_position[static_cast<std::size_t>(neighbor)]);
                    if (static_cast<std::int64_t>(weight) < heap[heap_index]) {
                        heap[heap_index] = weight;
                        decrease_key(weight, heap_index, heap, positions, node_position);
                        parent[static_cast<std::size_t>(neighbor)] = vertex;
                    }
                }
            }
        }
    }
    if (tree_edge_count != vertex_count - 1) return -1;
    words[0] = static_cast<std::int32_t>(tree_edge_count);
    const auto byte_count = word_count * 4;
    if (byte_count > max_output_bytes || output == nullptr || capacity < byte_count) return -2;
    std::array<std::uint8_t, max_output_bytes> buffer{};
    for (std::size_t index = 0; index < word_count; ++index)
        put_i32_le(buffer.data(), index * 4, words[index]);
    for (std::size_t index = 0; index < byte_count; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(byte_count);
}
