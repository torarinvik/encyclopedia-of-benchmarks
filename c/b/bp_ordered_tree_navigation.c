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

int64_t bp_ordered_tree_navigation(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + (n - 1) + 3 * q) return -1;

    int parent[MAX_N] = {0};
    for (size_t vertex = 1; vertex < n; ++vertex) {
        const int64_t value = input[1 + vertex];
        if (value < 0 || (uint64_t)value >= vertex) return -1;
        parent[vertex] = (int)value;
    }
    const size_t query_base = n + 1;
    const size_t bit_length = 2 * n;
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || (uint64_t)first > bit_length ||
                second < -(int64_t)bit_length || second > (int64_t)bit_length) return -1;
        } else if (opcode == 2) {
            if (first < 0 || second < first || (uint64_t)second >= bit_length) return -1;
        } else if (opcode >= 3 && opcode <= 5) {
            if (first < 0 || (uint64_t)first >= bit_length || second != 0) return -1;
        } else return -1;
    }

    uint8_t bits[MAX_BITS] = {0};
    size_t bit_count = 0, depth = 1;
    size_t stack_node[MAX_N + 1] = {0}, next_child[MAX_N + 1] = {0};
    bits[bit_count++] = 1;
    next_child[0] = 1;
    while (depth > 0) {
        const size_t frame = depth - 1;
        const size_t node = stack_node[frame];
        size_t child = next_child[frame];
        while (child < n && (size_t)parent[child] != node) ++child;
        if (child < n) {
            next_child[frame] = child + 1;
            bits[bit_count++] = 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            ++depth;
        } else {
            bits[bit_count++] = 0;
            --depth;
        }
    }
    if (bit_count != bit_length) return -1;

    int64_t excess[MAX_BITS + 1] = {0};
    uint64_t packed = 0;
    for (size_t position = 0; position < bit_length; ++position) {
        if (bits[position] != 0) packed |= UINT64_C(1) << position;
        excess[position + 1] = excess[position] + (bits[position] ? 1 : -1);
    }
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset], first_value = input[offset + 1];
        const int64_t second = input[offset + 2];
        if (opcode == 3 && bits[(size_t)first_value] != 1) return -1;
        if (opcode == 4 && bits[(size_t)first_value] != 0) return -1;
        if (opcode == 5 && bits[(size_t)first_value] != 1) return -1;
    }

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = n_value;
    words[1] = (int64_t)bit_length;
    words[2] = (int64_t)packed;
    words[3] = q_value;
    for (size_t index = 0; index < q; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset];
        const size_t first = (size_t)input[offset + 1];
        const int64_t second = input[offset + 2];
        int64_t answer = -1;
        if (opcode == 0 || opcode == 1) {
            const int64_t target = excess[first] + second;
            if (opcode == 0) {
                answer = (int64_t)bit_length + 1;
                for (size_t position = first + 1; position <= bit_length; ++position)
                    if (excess[position] == target) { answer = (int64_t)position; break; }
            } else {
                answer = 0;
                for (size_t position = first; position > 0; --position)
                    if (excess[position - 1] == target) { answer = (int64_t)(position - 1); break; }
            }
        } else if (opcode == 2) {
            const size_t right = (size_t)second;
            size_t best = first;
            for (size_t position = first + 1; position <= right; ++position)
                if (excess[position + 1] < excess[best + 1]) best = position;
            answer = (int64_t)best;
        } else if (opcode == 3) {
            const int64_t target = excess[first + 1] - 1;
            for (size_t position = first + 2; position <= bit_length; ++position)
                if (excess[position] == target) { answer = (int64_t)(position - 1); break; }
        } else if (opcode == 4) {
            const int64_t target = excess[first + 1];
            for (size_t position = first + 1; position > 0; --position)
                if (excess[position - 1] == target) { answer = (int64_t)(position - 1); break; }
        } else if (first == 0) {
            answer = -1;
        } else {
            const int64_t target = excess[first + 1] - 2;
            for (size_t position = first + 1; position > 0; --position)
                if (excess[position - 1] == target) { answer = (int64_t)(position - 1); break; }
        }
        words[4 + index] = answer;
    }

    const size_t output_words = 4 + q, required = 8 * output_words;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < output_words; ++index)
        write_i64_le(output, 8 * index, words[index]);
    return (int64_t)required;
}
