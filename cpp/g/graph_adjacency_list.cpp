/* Bounded graph ADT trace preserving adjacency-list insertion order. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_degree = 34;

int find_vertex(const int order[max_vertices], int count, int value) noexcept {
    for (int i = 0; i < count; ++i) if (order[i] == value) return i;
    return -1;
}

int find_neighbor(const int rows[max_vertices][max_degree], const int degree[max_vertices],
                  int vertex, int neighbor) noexcept {
    for (int i = 0; i < degree[vertex]; ++i) if (rows[vertex][i] == neighbor) return i;
    return -1;
}

void remove_neighbor(int rows[max_vertices][max_degree], int degree[max_vertices],
                     int vertex, int index) noexcept {
    for (int i = index; i + 1 < degree[vertex]; ++i) rows[vertex][i] = rows[vertex][i + 1];
    --degree[vertex];
}

void put_i64_le(std::uint8_t *output, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t graph_adjacency_list(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4) return -1;
    const auto directed_value = input[0], initial_count_value = input[1];
    if ((directed_value != 0 && directed_value != 1) || initial_count_value < 0 ||
        initial_count_value > 32 || length < 4 + static_cast<std::size_t>(initial_count_value)) return -1;

    const int directed = static_cast<int>(directed_value);
    int order[max_vertices]{};
    int rows[max_vertices][max_degree]{};
    int degree[max_vertices]{};
    int count = static_cast<int>(initial_count_value);
    std::size_t position = 2;
    for (int i = 0; i < count; ++i) {
        const auto value = input[position++];
        if (value < 0 || value >= 32 || find_vertex(order, i, static_cast<int>(value)) >= 0) return -1;
        order[i] = static_cast<int>(value);
    }

    const auto edge_count_value = input[position++];
    if (edge_count_value < 0 || edge_count_value > 1024 ||
        length < position + 2 * static_cast<std::size_t>(edge_count_value) + 1) return -1;
    for (std::int64_t edge = 0; edge < edge_count_value; ++edge) {
        const auto from_value = input[position++], to_value = input[position++];
        if (from_value < 0 || from_value >= 32 || to_value < 0 || to_value >= 32) return -1;
        const int from = static_cast<int>(from_value), to = static_cast<int>(to_value);
        if (find_vertex(order, count, from) < 0 || find_vertex(order, count, to) < 0 ||
            find_neighbor(rows, degree, from, to) >= 0) return -1;
        rows[from][degree[from]++] = to;
        if (!directed) rows[to][degree[to]++] = from;
    }

    const auto operation_count_value = input[position++];
    if (operation_count_value < 0 || operation_count_value > 64 ||
        length != position + 3 * static_cast<std::size_t>(operation_count_value)) return -1;
    const int operation_count = static_cast<int>(operation_count_value);
    std::int64_t results[64]{};
    for (int operation = 0; operation < operation_count; ++operation) {
        const auto code = input[position++], first_value = input[position++], second_value = input[position++];
        if (code == 0) {
            if (first_value < 0 || first_value >= 32 || second_value != 0 || count >= 32 ||
                find_vertex(order, count, static_cast<int>(first_value)) >= 0) return -1;
            const int vertex = static_cast<int>(first_value);
            order[count++] = vertex;
            degree[vertex] = 0;
            results[operation] = 1;
        } else if (code == 1) {
            if (first_value < 0 || first_value >= 32 || second_value != 0) return -1;
            const int vertex = static_cast<int>(first_value);
            const int at = find_vertex(order, count, vertex);
            if (at < 0) return -1;
            for (int row = 0; row < count; ++row) {
                const int owner = order[row];
                int neighbor_index = 0;
                while (neighbor_index < degree[owner]) {
                    if (rows[owner][neighbor_index] == vertex)
                        remove_neighbor(rows, degree, owner, neighbor_index);
                    else
                        ++neighbor_index;
                }
            }
            for (int i = at; i + 1 < count; ++i) order[i] = order[i + 1];
            --count;
            degree[vertex] = 0;
            results[operation] = 1;
        } else if (code == 2 || code == 3 || code == 5) {
            if (first_value < 0 || first_value >= 32 || second_value < 0 || second_value >= 32) return -1;
            const int from = static_cast<int>(first_value), to = static_cast<int>(second_value);
            if (find_vertex(order, count, from) < 0 || find_vertex(order, count, to) < 0) return -1;
            const int at = find_neighbor(rows, degree, from, to);
            if (code == 5) {
                results[operation] = at >= 0;
            } else if (code == 2) {
                if (at >= 0) return -1;
                rows[from][degree[from]++] = to;
                if (!directed) rows[to][degree[to]++] = from;
                results[operation] = 1;
            } else {
                if (at < 0) return -1;
                remove_neighbor(rows, degree, from, at);
                if (!directed) {
                    const int reverse = find_neighbor(rows, degree, to, from);
                    if (reverse < 0) return -1;
                    remove_neighbor(rows, degree, to, reverse);
                }
                results[operation] = 1;
            }
        } else if (code == 4) {
            if (first_value < 0 || first_value >= 32 || second_value != 0) return -1;
            results[operation] = find_vertex(order, count, static_cast<int>(first_value)) >= 0;
        } else if (code == 6) {
            if (first_value != 0 || second_value != 0) return -1;
            count = 0;
            for (int vertex = 0; vertex < 32; ++vertex) degree[vertex] = 0;
            results[operation] = 1;
        } else {
            return -1;
        }
    }

    std::size_t words = 2 + static_cast<std::size_t>(operation_count);
    for (int i = 0; i < count; ++i) words += 2 + static_cast<std::size_t>(degree[order[i]]);
    const auto output_bytes = words * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t word = 0;
    put_i64_le(output, word++, operation_count);
    for (int i = 0; i < operation_count; ++i) put_i64_le(output, word++, results[i]);
    put_i64_le(output, word++, count);
    for (int i = 0; i < count; ++i) {
        const int vertex = order[i];
        put_i64_le(output, word++, vertex);
        put_i64_le(output, word++, degree[vertex]);
        for (int j = 0; j < degree[vertex]; ++j) put_i64_le(output, word++, rows[vertex][j]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
