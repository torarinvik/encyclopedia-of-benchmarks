#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 31, MAX_Q = 32, MAX_INPUT = 129, MAX_BITS = 2 * MAX_N,
       MAX_OUTPUT_WORDS = 4 + MAX_Q };

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int bit_at(uint64_t bits, size_t position)
{
    return (int)((bits >> (position - 1)) & UINT64_C(1));
}

static size_t find_close(uint64_t bits, size_t bit_length, size_t open_position)
{
    int balance = 0;
    for (size_t position = open_position; position <= bit_length; ++position) {
        balance += bit_at(bits, position) ? 1 : -1;
        if (balance == 0) return position;
    }
    return bit_length + 1;
}

static size_t find_open(uint64_t bits, size_t position)
{
    if (bit_at(bits, position)) return position;
    int balance = 0;
    for (size_t candidate = position; candidate > 0; --candidate) {
        balance += bit_at(bits, candidate) ? -1 : 1;
        if (balance == 0) return candidate;
    }
    return 0;
}

static size_t previous_zero(uint64_t bits, size_t position)
{
    for (size_t candidate = position; candidate > 1; --candidate)
        if (!bit_at(bits, candidate - 1)) return candidate - 1;
    return 0;
}

int64_t dfuds_ordered_tree_navigation(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + (n - 1) + 3 * q) return -1;

    size_t parent[MAX_N] = {0};
    for (size_t vertex = 1; vertex < n; ++vertex) {
        const int64_t value = input[1 + vertex];
        if (value < 0 || (uint64_t)value >= vertex) return -1;
        parent[vertex] = (size_t)value;
    }
    const size_t query_base = n + 1;
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset], node = input[offset + 1], argument = input[offset + 2];
        if (node < 0 || (uint64_t)node >= n) return -1;
        if (opcode == 0 || opcode == 2) {
            if (argument != 0) return -1;
        } else if (opcode == 1) {
            if (argument < 0 || (uint64_t)argument > n) return -1;
        } else return -1;
    }

    size_t order[MAX_N] = {0}, stack_node[MAX_N] = {0}, next_child[MAX_N] = {0};
    size_t order_count = 1, depth = 1;
    stack_node[0] = 0;
    next_child[0] = 1;
    while (depth > 0) {
        const size_t frame = depth - 1;
        const size_t node = stack_node[frame];
        size_t child = next_child[frame];
        while (child < n && parent[child] != node) ++child;
        if (child < n) {
            next_child[frame] = child + 1;
            order[order_count++] = child;
            stack_node[depth] = child;
            next_child[depth] = 1;
            ++depth;
        } else {
            --depth;
        }
    }
    if (order_count != n) return -1;

    size_t descriptor[MAX_N] = {0};
    int position_to_node[MAX_BITS + 2];
    for (size_t position = 0; position < MAX_BITS + 2; ++position) position_to_node[position] = -1;
    uint64_t packed = UINT64_C(1); /* dummy opening bit */
    size_t bit_length = 1;
    for (size_t node = 0; node < n; ++node) {
        size_t degree = 0;
        for (size_t child = 1; child < n; ++child)
            if (parent[child] == order[node]) ++degree;
        descriptor[node] = bit_length + 1;
        position_to_node[descriptor[node]] = (int)node;
        for (size_t child = 0; child < degree; ++child)
            packed |= UINT64_C(1) << bit_length++;
        ++bit_length; /* terminating zero */
    }
    if (bit_length != 2 * n) return -1;

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = n_value;
    words[1] = (int64_t)bit_length;
    words[2] = (int64_t)packed;
    words[3] = q_value;
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset];
        const size_t node = (size_t)input[offset + 1];
        const int64_t argument = input[offset + 2];
        const size_t start = descriptor[node];
        size_t degree = 0;
        while (start + degree <= bit_length && bit_at(packed, start + degree)) ++degree;
        int64_t answer = -1;
        if (opcode == 0) {
            answer = (int64_t)degree;
        } else if (opcode == 1) {
            if ((uint64_t)argument < degree) {
                const size_t target = start + degree - ((size_t)argument + 1);
                const size_t child_start = find_close(packed, bit_length, target) + 1;
                if (child_start > MAX_BITS + 1 || position_to_node[child_start] < 0) return -1;
                answer = position_to_node[child_start];
            }
        } else if (node != 0) {
            const size_t matched_open = find_open(packed, start - 1);
            const size_t parent_position = previous_zero(packed, matched_open) + 1;
            if (parent_position == 1) answer = 0; /* dummy descriptor denotes the real root */
            else if (parent_position <= MAX_BITS + 1 && position_to_node[parent_position] >= 0)
                answer = position_to_node[parent_position];
            else return -1;
        }
        words[4 + index] = answer;
    }

    const size_t output_words = 4 + q, required = 8 * output_words;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < output_words; ++index)
        write_i64_le(output, 8 * index, words[index]);
    return (int64_t)required;
}
