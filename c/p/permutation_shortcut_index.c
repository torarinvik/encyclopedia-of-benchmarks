#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_QUERIES 16
#define MAX_INPUT 52

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static int is_marked(uint32_t bit_vector, int vertex)
{
    return (bit_vector & (UINT32_C(1) << (unsigned)vertex)) != 0;
}

static int shortcut_inverse(int target, int n, const int *successor,
                            uint32_t bit_vector, const int *shortcuts)
{
    int marker = target;
    int steps = 0;
    while (steps < n && !is_marked(bit_vector, marker)) {
        marker = successor[marker];
        ++steps;
    }
    if (!is_marked(bit_vector, marker)) {
        int previous = target;
        int current = successor[target];
        while (current != target) { previous = current; current = successor[current]; }
        return previous;
    }
    int rank = 0;
    for (int vertex = 0; vertex < marker; ++vertex) rank += is_marked(bit_vector, vertex);
    int current = shortcuts[rank];
    int previous = current;
    current = successor[current];
    for (steps = 0; steps < n; ++steps) {
        if (current == target) return previous;
        previous = current;
        current = successor[current];
    }
    return -1;
}

int64_t permutation_shortcut_index(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], stride_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || stride_raw < 1 || stride_raw > MAX_N) return -1;
    const int n = (int)n_raw, stride = (int)stride_raw;
    const size_t query_at = 2 + (size_t)n;
    if (length <= query_at) return -1;
    const int64_t query_raw = input[query_at];
    if (query_raw < 0 || query_raw > MAX_QUERIES
        || length != query_at + 1 + 2 * (size_t)query_raw) return -1;
    const int query_count = (int)query_raw;
    int successor[MAX_N];
    uint8_t seen[MAX_N] = {0};
    for (int vertex = 0; vertex < n; ++vertex) {
        const int64_t value = input[2 + (size_t)vertex];
        if (value < 1 || value > n || seen[value - 1]) return -1;
        seen[value - 1] = 1;
        successor[vertex] = (int)value - 1;
    }
    for (int query = 0; query < query_count; ++query) {
        const int64_t op = input[query_at + 1 + 2 * (size_t)query];
        const int64_t index = input[query_at + 2 + 2 * (size_t)query];
        if ((op != 0 && op != 1) || index < 1 || index > n) return -1;
    }

    uint8_t visited[MAX_N] = {0};
    int back_pointer[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) back_pointer[vertex] = -1;
    uint32_t bit_vector = 0;
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int cycle[MAX_N];
        int cycle_length = 0;
        int current = start;
        while (!visited[current]) {
            visited[current] = 1;
            cycle[cycle_length++] = current;
            current = successor[current];
        }
        if (cycle_length >= stride) {
            for (int offset = 0; offset < cycle_length; offset += stride) {
                const int vertex = cycle[offset];
                bit_vector |= UINT32_C(1) << (unsigned)vertex;
                int back_offset = (offset - stride) % cycle_length;
                if (back_offset < 0) back_offset += cycle_length;
                back_pointer[vertex] = cycle[back_offset];
            }
        }
    }
    int shortcuts[MAX_N];
    int shortcut_count = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if (is_marked(bit_vector, vertex)) shortcuts[shortcut_count++] = back_pointer[vertex];

    int64_t answers[MAX_QUERIES];
    for (int query = 0; query < query_count; ++query) {
        const int64_t op = input[query_at + 1 + 2 * (size_t)query];
        const int target = (int)input[query_at + 2 + 2 * (size_t)query] - 1;
        const int answer = op == 0 ? successor[target]
                                   : shortcut_inverse(target, n, successor, bit_vector, shortcuts);
        if (answer < 0) return -1;
        answers[query] = (int64_t)answer + 1;
    }
    const size_t bytes = (size_t)query_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (int query = 0; query < query_count; ++query)
        store_i64_le(output, (size_t)query * 8, answers[query]);
    return (int64_t)bytes;
}
