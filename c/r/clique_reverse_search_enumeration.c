#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT (MAX_N + 1)
#define MAX_CLIQUES 256
#define MAX_OUTPUT_BYTES (8 + MAX_CLIQUES)

typedef struct {
    size_t n;
    uint16_t adjacency[MAX_N];
    uint8_t masks[MAX_CLIQUES];
    size_t count;
} SearchState;

static void visit(SearchState *state, uint16_t clique)
{
    state->masks[state->count++] = (uint8_t)clique;
    size_t minimum = state->n;
    for (size_t vertex = 0; vertex < state->n; ++vertex) {
        if ((clique & ((uint16_t)1U << vertex)) != 0) { minimum = vertex; break; }
    }
    for (size_t vertex = 0; vertex < minimum; ++vertex) {
        uint16_t bit = (uint16_t)1U << vertex;
        if ((clique & bit) == 0 && (state->adjacency[vertex] & clique) == clique)
            visit(state, (uint16_t)(clique | bit));
    }
}

static void store_i64_le(uint8_t *output, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t clique_reverse_search_enumeration(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    SearchState state = {0};
    state.n = n;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const int64_t raw = input[vertex + 1];
        if (raw < 0 || raw >= (1 << n) || (raw & (1 << vertex)) != 0) return -1;
        state.adjacency[vertex] = (uint16_t)raw;
    }
    for (size_t left = 0; left < n; ++left) {
        for (size_t right = left + 1; right < n; ++right) {
            const bool edge_left = (state.adjacency[left] & ((uint16_t)1U << right)) != 0;
            const bool edge_right = (state.adjacency[right] & ((uint16_t)1U << left)) != 0;
            if (edge_left != edge_right) return -1;
        }
    }
    visit(&state, 0);
    const size_t required = 8 + state.count;
    if (output == NULL || capacity < required) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, (int64_t)state.count);
    for (size_t index = 0; index < state.count; ++index) staged[8 + index] = state.masks[index];
    for (size_t byte = 0; byte < required; ++byte) output[byte] = staged[byte];
    return (int64_t)required;
}
