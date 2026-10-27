#include <stddef.h>
#include <stdint.h>

#define MAX_N 4
#define MAX_INPUT 2
#define MAX_WORDS 97
#define MAX_OUTPUT_BYTES (MAX_WORDS * 8)

typedef struct {
    size_t n;
    int64_t permutation[MAX_N];
    int64_t staged[MAX_WORDS];
    size_t cursor;
} SearchState;

static void visit(SearchState *state)
{
    for (size_t index = 0; index < state->n; ++index)
        state->staged[state->cursor++] = state->permutation[index];

    size_t reverse_point = state->n;
    for (size_t index = 0; index + 1 < state->n; ++index) {
        if (state->permutation[index] > state->permutation[index + 1]) {
            reverse_point = index + 1;
            break;
        }
    }

    for (size_t child = 1; child < reverse_point; ++child) {
        int64_t temporary = state->permutation[child - 1];
        state->permutation[child - 1] = state->permutation[child];
        state->permutation[child] = temporary;
        visit(state);
        temporary = state->permutation[child - 1];
        state->permutation[child - 1] = state->permutation[child];
        state->permutation[child] = temporary;
    }

    if (reverse_point + 2 <= state->n &&
        state->permutation[reverse_point - 1] < state->permutation[reverse_point + 1]) {
        size_t left = reverse_point;
        int64_t temporary = state->permutation[left];
        state->permutation[left] = state->permutation[left + 1];
        state->permutation[left + 1] = temporary;
        visit(state);
        temporary = state->permutation[left];
        state->permutation[left] = state->permutation[left + 1];
        state->permutation[left + 1] = temporary;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t reverse_search_permutation_enumeration(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;

    const size_t n = (size_t)input[0];
    size_t count = 1;
    for (size_t factor = 2; factor <= n; ++factor) count *= factor;
    const size_t words = 1 + n * count;
    const size_t required = words * 8;
    if (output == NULL || capacity < required) return -2;

    SearchState state = {0};
    state.n = n;
    state.cursor = 1;
    state.staged[0] = (int64_t)count;
    for (size_t index = 0; index < n; ++index)
        state.permutation[index] = (int64_t)index + 1;
    visit(&state);

    for (size_t word = 0; word < words; ++word)
        store_i64_le(output, word * 8, state.staged[word]);
    return (int64_t)required;
}
