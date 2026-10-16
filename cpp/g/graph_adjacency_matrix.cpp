// Bounded graph ADT trace backed by a compact adjacency matrix.
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 8;
constexpr int max_vertex_id_exclusive = 32;
constexpr int max_edges = 64;
constexpr int max_operations = 24;
void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
int vertex_index(const int *vertices, int count, int value) noexcept {
    for (int i = 0; i < count; ++i) if (vertices[i] == value) return i;
    return -1;
}
void remove_vertex(int *vertices, int matrix[max_vertices][max_vertices], int &count, int index) noexcept {
    const int old_count = count;
    for (int row = index; row + 1 < old_count; ++row) {
        vertices[row] = vertices[row + 1];
        for (int column = 0; column < old_count; ++column) matrix[row][column] = matrix[row + 1][column];
    }
    for (int row = 0; row + 1 < old_count; ++row)
        for (int column = index; column + 1 < old_count; ++column) matrix[row][column] = matrix[row][column + 1];
    for (int i = 0; i < old_count; ++i) matrix[old_count - 1][i] = matrix[i][old_count - 1] = 0;
    --count;
}
}

extern "C" std::int64_t graph_adjacency_matrix(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4) return -1;
    const auto directed_value = input[0], vertex_count_value = input[1];
    if ((directed_value != 0 && directed_value != 1) || vertex_count_value < 0 || vertex_count_value > max_vertices) return -1;
    const int directed = static_cast<int>(directed_value);
    int vertex_count = static_cast<int>(vertex_count_value);
    if (length < static_cast<std::size_t>(3 + vertex_count)) return -1;

    int vertices[max_vertices]{};
    int matrix[max_vertices][max_vertices]{};
    std::size_t position = 2;
    for (int i = 0; i < vertex_count; ++i) {
        const auto value = input[position++];
        if (value < 0 || value >= max_vertex_id_exclusive || vertex_index(vertices, i, static_cast<int>(value)) >= 0) return -1;
        vertices[i] = static_cast<int>(value);
    }
    if (position >= length) return -1;
    const auto edge_count_value = input[position++];
    if (edge_count_value < 0 || edge_count_value > max_edges || length < position + 2 * static_cast<std::size_t>(edge_count_value) + 1) return -1;
    for (int edge = 0; edge < edge_count_value; ++edge) {
        const auto source_value = input[position++], destination_value = input[position++];
        if (source_value < 0 || source_value >= max_vertex_id_exclusive || destination_value < 0 || destination_value >= max_vertex_id_exclusive) return -1;
        const int source = vertex_index(vertices, vertex_count, static_cast<int>(source_value));
        const int destination = vertex_index(vertices, vertex_count, static_cast<int>(destination_value));
        if (source < 0 || destination < 0 || matrix[source][destination]) return -1;
        matrix[source][destination] = 1;
        if (!directed) matrix[destination][source] = 1;
    }
    const auto operation_count_value = input[position++];
    if (operation_count_value < 0 || operation_count_value > max_operations || length != position + 3 * static_cast<std::size_t>(operation_count_value)) return -1;
    const int operation_count = static_cast<int>(operation_count_value);
    int results[max_operations]{};

    for (int operation_index = 0; operation_index < operation_count; ++operation_index) {
        const auto operation = input[position++], a_value = input[position++], b_value = input[position++];
        if (operation == 0) {
            if (a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0 || vertex_index(vertices, vertex_count, static_cast<int>(a_value)) >= 0 || vertex_count >= max_vertices) return -1;
            for (int i = 0; i < max_vertices; ++i) matrix[i][vertex_count] = matrix[vertex_count][i] = 0;
            vertices[vertex_count++] = static_cast<int>(a_value);
            results[operation_index] = 1;
        } else if (operation == 1) {
            if (a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0) return -1;
            const int removed = vertex_index(vertices, vertex_count, static_cast<int>(a_value));
            if (removed < 0) return -1;
            remove_vertex(vertices, matrix, vertex_count, removed);
            results[operation_index] = 1;
        } else if (operation == 2 || operation == 3 || operation == 5) {
            if (a_value < 0 || a_value >= max_vertex_id_exclusive || b_value < 0 || b_value >= max_vertex_id_exclusive) return -1;
            const int source = vertex_index(vertices, vertex_count, static_cast<int>(a_value));
            const int destination = vertex_index(vertices, vertex_count, static_cast<int>(b_value));
            if (source < 0 || destination < 0) return -1;
            const bool present = matrix[source][destination] != 0;
            if (operation == 5) results[operation_index] = present;
            else if (operation == 2) {
                if (present) return -1;
                matrix[source][destination] = 1;
                if (!directed) matrix[destination][source] = 1;
                results[operation_index] = 1;
            } else {
                if (!present) return -1;
                matrix[source][destination] = 0;
                if (!directed) matrix[destination][source] = 0;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0) return -1;
            results[operation_index] = vertex_index(vertices, vertex_count, static_cast<int>(a_value)) >= 0;
        } else if (operation == 6) {
            if (a_value != 0 || b_value != 0) return -1;
            vertex_count = 0;
            for (auto &row : matrix) for (int &cell : row) cell = 0;
            results[operation_index] = 1;
        } else return -1;
    }

    const auto words = std::size_t{2} + static_cast<std::size_t>(operation_count) + static_cast<std::size_t>(vertex_count) + static_cast<std::size_t>(vertex_count * vertex_count);
    if (output == nullptr || capacity < words * 8) return -2;
    std::size_t word = 0;
    put_i64(output, word++, operation_count);
    for (int i = 0; i < operation_count; ++i) put_i64(output, word++, results[i]);
    put_i64(output, word++, vertex_count);
    for (int i = 0; i < vertex_count; ++i) put_i64(output, word++, vertices[i]);
    for (int row = 0; row < vertex_count; ++row)
        for (int column = 0; column < vertex_count; ++column) put_i64(output, word++, matrix[row][column]);
    return static_cast<std::int64_t>(words * 8);
}
