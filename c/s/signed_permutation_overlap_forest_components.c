#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_VERTICES (2 * MAX_N + 2)
#define MAX_CYCLES (MAX_N + 1)
#define MAX_INPUT (MAX_N + 2)
#define MAX_OUTPUT_WORDS (1 + 3 * MAX_CYCLES)
#define MAX_OUTPUT_BYTES (8 * MAX_OUTPUT_WORDS)

static void store_i64(uint8_t *bytes, size_t word, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        bytes[word * 8 + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t signed_permutation_overlap_forest_components(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)(n_value + 1)) return -1;
    const int n = (int)n_value;
    const int vertices = 2 * n + 2;

    int64_t permutation[MAX_VERTICES] = {0};
    permutation[vertices - 1] = vertices - 1;
    uint16_t seen = 0;
    for (int position = 0; position < n; ++position) {
        const int64_t gene = input[position + 1];
        if (gene == 0 || gene < -n || gene > n) return -1;
        const int absolute = (int)(gene < 0 ? -gene : gene);
        const uint16_t bit = (uint16_t)(1u << (absolute - 1));
        if ((seen & bit) != 0) return -1;
        seen = (uint16_t)(seen | bit);
        int first = 2 * absolute - 1, second = 2 * absolute;
        if (gene < 0) { const int temporary = first; first = second; second = temporary; }
        permutation[2 * position + 1] = first;
        permutation[2 * position + 2] = second;
    }

    int gray[MAX_VERTICES];
    for (int vertex = 0; vertex < vertices; ++vertex) gray[vertex] = -1;
    for (int pair = 0; pair <= n; ++pair) {
        const int left = (int)permutation[2 * pair];
        const int right = (int)permutation[2 * pair + 1];
        gray[left] = right;
        gray[right] = left;
    }

    int cycle_of[MAX_VERTICES], begin[MAX_CYCLES], end[MAX_CYCLES];
    for (int vertex = 0; vertex < vertices; ++vertex) cycle_of[vertex] = -1;
    int cycle_count = 0;
    for (int start = 0; start < vertices; ++start) {
        if (cycle_of[start] >= 0) continue;
        const int cid = cycle_count++;
        int vertex = start, low = start, high = start;
        while (cycle_of[vertex] < 0) {
            cycle_of[vertex] = cid;
            if (vertex < low) low = vertex;
            if (vertex > high) high = vertex;
            vertex = gray[vertex ^ 1];
        }
        begin[cid] = low;
        end[cid] = high;
    }

    int parent[MAX_CYCLES];
    for (int cid = 0; cid < cycle_count; ++cid) parent[cid] = cid;
    int stack_id[MAX_CYCLES], stack_begin[MAX_CYCLES], stack_end[MAX_CYCLES];
    int stack_size = 0;
    for (int vertex = 0; vertex < vertices; ++vertex) {
        const int cid = cycle_of[vertex];
        const int low = begin[cid], high = end[cid];
        if (vertex == low) {
            stack_id[stack_size] = cid;
            stack_begin[stack_size] = low;
            stack_end[stack_size] = high;
            ++stack_size;
        }
        int extent_begin = low, extent_end = high;
        while (stack_size > 0 && stack_begin[stack_size - 1] > low) {
            --stack_size;
            const int popped = stack_id[stack_size];
            if (stack_begin[stack_size] < extent_begin) extent_begin = stack_begin[stack_size];
            if (stack_end[stack_size] > extent_end) extent_end = stack_end[stack_size];
            parent[popped] = cid;
        }
        if (stack_size == 0) return -1;
        if (extent_begin < stack_begin[stack_size - 1]) stack_begin[stack_size - 1] = extent_begin;
        if (extent_end > stack_end[stack_size - 1]) stack_end[stack_size - 1] = extent_end;
        if (vertex == stack_end[stack_size - 1]) --stack_size;
    }

    int component[MAX_CYCLES];
    for (int cid = 0; cid < cycle_count; ++cid)
        component[cid] = parent[cid] == cid ? begin[cid] : component[parent[cid]];
    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = cycle_count;
    for (int cid = 0; cid < cycle_count; ++cid) {
        words[1 + 3 * cid] = begin[cid];
        words[2 + 3 * cid] = end[cid];
        words[3 + 3 * cid] = component[cid];
    }
    const size_t output_bytes = (size_t)(1 + 3 * cycle_count) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (int word = 0; word < 1 + 3 * cycle_count; ++word)
        store_i64(staged, (size_t)word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
