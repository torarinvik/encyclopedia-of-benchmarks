/* Clean-room power-of-two Sqrt Tree range-minimum profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_QUERIES 64
#define MAX_LEVELS 4
#define MAX_INPUT_VALUES 195
#define VALUE_LIMIT INT64_C(1000000000)

typedef struct {
    int64_t values[MAX_ITEMS];
    int64_t prefix[MAX_LEVELS][MAX_ITEMS];
    int64_t suffix[MAX_LEVELS][MAX_ITEMS];
    int64_t between[MAX_LEVELS][MAX_ITEMS];
    size_t floor_log[MAX_ITEMS + 1];
    size_t padded_size;
    size_t layer_count;
    size_t segment_bits[MAX_LEVELS];
    size_t block_bits[MAX_LEVELS];
    int layer_for_diff[MAX_LEVELS + 3];
} SqrtTreeConstantState;

static int64_t min_i64(int64_t a, int64_t b) { return a < b ? a : b; }

static void build_sqrt_tree(SqrtTreeConstantState *state, const int64_t *input, size_t n)
{
    size_t padded = 1;
    while (padded < n) padded *= 2;
    state->padded_size = padded;
    for (size_t i = 0; i < n; ++i) state->values[i] = input[2 + i];
    for (size_t i = n; i < padded; ++i) state->values[i] = INT64_MAX;
    state->floor_log[0] = 0;
    if (padded >= 1) state->floor_log[1] = 0;
    for (size_t i = 2; i <= padded; ++i) state->floor_log[i] = state->floor_log[i / 2] + 1;
    for (size_t i = 0; i < MAX_LEVELS + 3; ++i) state->layer_for_diff[i] = -1;

    size_t segment_bits = state->floor_log[padded];
    state->layer_count = 0;
    while (segment_bits > 1) {
        const size_t level = state->layer_count++;
        const size_t block_bits = (segment_bits + 1) / 2;
        state->segment_bits[level] = segment_bits;
        state->block_bits[level] = block_bits;
        for (size_t bit = block_bits; bit < segment_bits; ++bit)
            state->layer_for_diff[bit] = (int)level;
        segment_bits = block_bits;
    }

    for (size_t level = 0; level < state->layer_count; ++level) {
        const size_t seg_bits = state->segment_bits[level];
        const size_t blk_bits = state->block_bits[level];
        const size_t segment_size = (size_t)1 << seg_bits;
        const size_t block_size = (size_t)1 << blk_bits;
        const size_t block_count = segment_size / block_size;
        const size_t pair_count = block_count * block_count;
        for (size_t base = 0; base < padded; base += segment_size) {
            const size_t segment_index = base / segment_size;
            for (size_t block = 0; block < block_count; ++block) {
                const size_t start = base + block * block_size;
                const size_t end = start + block_size;
                state->prefix[level][start] = state->values[start];
                for (size_t i = start + 1; i < end; ++i)
                    state->prefix[level][i] = min_i64(state->prefix[level][i - 1], state->values[i]);
                state->suffix[level][end - 1] = state->values[end - 1];
                size_t i = end - 1;
                while (i > start) {
                    --i;
                    state->suffix[level][i] = min_i64(state->values[i], state->suffix[level][i + 1]);
                }
            }
            for (size_t left = 0; left < block_count; ++left) {
                int64_t aggregate = INT64_MAX;
                for (size_t right = left; right < block_count; ++right) {
                    const size_t start = base + right * block_size;
                    aggregate = min_i64(aggregate, state->suffix[level][start]);
                    const size_t slot = segment_index * pair_count + left * block_count + right;
                    state->between[level][slot] = aggregate;
                }
            }
        }
    }
}

static int64_t query_min(const SqrtTreeConstantState *state, size_t left, size_t right)
{
    if (left == right) return state->values[left];
    const size_t difference = left ^ right;
    const size_t bit = state->floor_log[difference];
    if (bit == 0) return min_i64(state->values[left], state->values[right]);
    const size_t level = (size_t)state->layer_for_diff[bit];
    const size_t segment_bits = state->segment_bits[level];
    const size_t block_bits = state->block_bits[level];
    const size_t segment_size = (size_t)1 << segment_bits;
    const size_t block_size = (size_t)1 << block_bits;
    const size_t base = (left / segment_size) * segment_size;
    const size_t segment_index = base / segment_size;
    const size_t block_count = segment_size / block_size;
    const size_t left_block = (left - base) / block_size;
    const size_t right_block = (right - base) / block_size;
    int64_t answer = min_i64(state->suffix[level][left], state->prefix[level][right]);
    if (left_block + 1 < right_block) {
        const size_t pair_count = block_count * block_count;
        const size_t slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1;
        answer = min_i64(answer, state->between[level][slot]);
    }
    return answer;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t sqrt_tree_constant_time(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    const int64_t q_value = input[1];
    if (n_value < 1 || n_value > MAX_ITEMS || q_value < 0 || q_value > MAX_QUERIES) return -1;
    const size_t n = (size_t)n_value;
    const size_t q = (size_t)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[2 + i] < -VALUE_LIMIT || input[2 + i] > VALUE_LIMIT) return -1;
    const size_t query_offset = 2 + n;
    for (size_t query = 0; query < q; ++query) {
        const int64_t left = input[query_offset + 2 * query];
        const int64_t right = input[query_offset + 2 * query + 1];
        if (left < 0 || right < left || right >= n_value) return -1;
    }
    const size_t required = 8 * q;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;

    SqrtTreeConstantState state = {0};
    build_sqrt_tree(&state, input, n);
    for (size_t query = 0; query < q; ++query) {
        const size_t left = (size_t)input[query_offset + 2 * query];
        const size_t right = (size_t)input[query_offset + 2 * query + 1];
        store_i64_le(output, 8 * query, query_min(&state, left, right));
    }
    return (int64_t)required;
}
