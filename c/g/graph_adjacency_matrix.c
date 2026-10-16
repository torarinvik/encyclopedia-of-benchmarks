/* Bounded graph ADT trace backed by a compact adjacency matrix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_VERTEX_ID_EXCLUSIVE 32
#define MAX_EDGES 64
#define MAX_OPERATIONS 24

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

static int vertex_index(const int *vertices, int count, int value) {
    for (int i = 0; i < count; ++i) if (vertices[i] == value) return i;
    return -1;
}

static void remove_vertex(int *vertices, uint8_t matrix[MAX_VERTICES][MAX_VERTICES], int *count, int index) {
    int old_count = *count;
    for (int row = index; row + 1 < old_count; ++row) {
        vertices[row] = vertices[row + 1];
        for (int column = 0; column < old_count; ++column) matrix[row][column] = matrix[row + 1][column];
    }
    for (int row = 0; row + 1 < old_count; ++row)
        for (int column = index; column + 1 < old_count; ++column) matrix[row][column] = matrix[row][column + 1];
    for (int i = 0; i < old_count; ++i) matrix[old_count - 1][i] = matrix[i][old_count - 1] = 0;
    *count = old_count - 1;
}

int64_t graph_adjacency_matrix(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 4) return -1;
    int64_t directed_value = input[0], vertex_count_value = input[1];
    if ((directed_value != 0 && directed_value != 1) || vertex_count_value < 0 || vertex_count_value > MAX_VERTICES) return -1;
    int directed = (int)directed_value, vertex_count = (int)vertex_count_value;
    if (length < (size_t)(3 + vertex_count)) return -1;

    int vertices[MAX_VERTICES] = {0};
    uint8_t matrix[MAX_VERTICES][MAX_VERTICES] = {{0}};
    size_t position = 2;
    for (int i = 0; i < vertex_count; ++i) {
        int64_t value = input[position++];
        if (value < 0 || value >= MAX_VERTEX_ID_EXCLUSIVE || vertex_index(vertices, i, (int)value) >= 0) return -1;
        vertices[i] = (int)value;
    }
    if (position >= length) return -1;
    int64_t edge_count_value = input[position++];
    if (edge_count_value < 0 || edge_count_value > MAX_EDGES || length < position + 2 * (size_t)edge_count_value + 1) return -1;
    for (int edge = 0; edge < (int)edge_count_value; ++edge) {
        int64_t source_value = input[position++], destination_value = input[position++];
        if (source_value < 0 || source_value >= MAX_VERTEX_ID_EXCLUSIVE || destination_value < 0 || destination_value >= MAX_VERTEX_ID_EXCLUSIVE) return -1;
        int source = vertex_index(vertices, vertex_count, (int)source_value);
        int destination = vertex_index(vertices, vertex_count, (int)destination_value);
        if (source < 0 || destination < 0 || matrix[source][destination]) return -1;
        matrix[source][destination] = 1;
        if (!directed) matrix[destination][source] = 1;
    }
    int64_t operation_count_value = input[position++];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS || length != position + 3 * (size_t)operation_count_value) return -1;
    int operation_count = (int)operation_count_value, results[MAX_OPERATIONS] = {0};

    for (int operation_index = 0; operation_index < operation_count; ++operation_index) {
        int64_t operation = input[position++], a_value = input[position++], b_value = input[position++];
        if (operation == 0) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0 || vertex_index(vertices, vertex_count, (int)a_value) >= 0 || vertex_count >= MAX_VERTICES) return -1;
            for (int i = 0; i < MAX_VERTICES; ++i) matrix[i][vertex_count] = matrix[vertex_count][i] = 0;
            vertices[vertex_count++] = (int)a_value;
            results[operation_index] = 1;
        } else if (operation == 1) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0) return -1;
            int removed = vertex_index(vertices, vertex_count, (int)a_value);
            if (removed < 0) return -1;
            remove_vertex(vertices, matrix, &vertex_count, removed);
            results[operation_index] = 1;
        } else if (operation == 2 || operation == 3 || operation == 5) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value < 0 || b_value >= MAX_VERTEX_ID_EXCLUSIVE) return -1;
            int source = vertex_index(vertices, vertex_count, (int)a_value);
            int destination = vertex_index(vertices, vertex_count, (int)b_value);
            if (source < 0 || destination < 0) return -1;
            int present = matrix[source][destination] != 0;
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
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0) return -1;
            results[operation_index] = vertex_index(vertices, vertex_count, (int)a_value) >= 0;
        } else if (operation == 6) {
            if (a_value != 0 || b_value != 0) return -1;
            vertex_count = 0;
            for (int row = 0; row < MAX_VERTICES; ++row)
                for (int column = 0; column < MAX_VERTICES; ++column) matrix[row][column] = 0;
            results[operation_index] = 1;
        } else return -1;
    }

    size_t words = 2 + (size_t)operation_count + (size_t)vertex_count + (size_t)vertex_count * (size_t)vertex_count;
    if (!output || capacity < words * 8) return -2;
    size_t word = 0;
    put_i64(output, word++, operation_count);
    for (int i = 0; i < operation_count; ++i) put_i64(output, word++, results[i]);
    put_i64(output, word++, vertex_count);
    for (int i = 0; i < vertex_count; ++i) put_i64(output, word++, vertices[i]);
    for (int row = 0; row < vertex_count; ++row)
        for (int column = 0; column < vertex_count; ++column) put_i64(output, word++, matrix[row][column]);
    return (int64_t)(words * 8);
}
