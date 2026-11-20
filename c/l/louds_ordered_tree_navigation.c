#include <stddef.h>
#include <stdint.h>

enum {
    MAX_NODES = 32,
    MAX_QUERIES = 32,
    MAX_INPUT_WORDS = 130,
    MAX_OUTPUT_WORDS = 4 + MAX_QUERIES
};

static void write_i64_le(uint8_t *output, size_t index, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    const size_t offset = index * 8;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t louds_ordered_tree_navigation(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t nodes_value = input[0];
    const int64_t queries_value = input[1];
    if (nodes_value < 1 || nodes_value > MAX_NODES
            || queries_value < 0 || queries_value > MAX_QUERIES) return -1;
    const size_t nodes = (size_t)nodes_value;
    const size_t queries = (size_t)queries_value;
    if (length != 2 + (nodes - 1) + 3 * queries) return -1;

    int parent[MAX_NODES];
    parent[0] = -1;
    for (size_t vertex = 1; vertex < nodes; ++vertex) {
        const int64_t value = input[1 + vertex];
        if (value < 0 || (uint64_t)value >= vertex) return -1;
        parent[vertex] = (int)value;
    }

    const size_t query_base = nodes + 1;
    for (size_t index = 0; index < queries; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset];
        const int64_t node = input[offset + 1];
        const int64_t argument = input[offset + 2];
        if (node < 0 || (uint64_t)node >= nodes) return -1;
        if (opcode == 0 || opcode == 1) {
            if (argument != 0) return -1;
        } else if (opcode == 2) {
            if (argument < 0 || (uint64_t)argument > nodes) return -1;
        } else {
            return -1;
        }
    }

    size_t level_order[MAX_NODES];
    size_t degrees[MAX_NODES] = {0};
    size_t order_count = 1;
    size_t order_cursor = 0;
    level_order[0] = 0;
    while (order_cursor < order_count) {
        const size_t vertex = level_order[order_cursor++];
        for (size_t child = 1; child < nodes; ++child) {
            if ((size_t)parent[child] == vertex)
                level_order[order_count++] = child;
        }
    }
    if (order_count != nodes) return -1;

    uint64_t packed = 0;
    size_t bit_length = 0;
    for (size_t node = 0; node < nodes; ++node) {
        const size_t vertex = level_order[node];
        for (size_t child = 1; child < nodes; ++child)
            if ((size_t)parent[child] == vertex) ++degrees[node];
        for (size_t child = 0; child < degrees[node]; ++child)
            packed |= UINT64_C(1) << bit_length++;
        ++bit_length; /* zero terminates this node's unary degree code */
    }

    size_t decoded_degrees[MAX_NODES] = {0};
    size_t rank_prefix[MAX_NODES + 1] = {0};
    size_t bit_position = 0;
    size_t previous_zero = (size_t)-1;
    for (size_t node = 0; node < nodes; ++node) {
        while (bit_position < bit_length
                && ((packed >> bit_position) & UINT64_C(1)) != 0)
            ++bit_position;
        if (bit_position >= bit_length) return -1;
        decoded_degrees[node] = bit_position - (previous_zero + 1);
        rank_prefix[node + 1] = rank_prefix[node] + decoded_degrees[node];
        previous_zero = bit_position++;
    }

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = (int64_t)nodes;
    words[1] = (int64_t)bit_length;
    words[2] = (int64_t)packed;
    words[3] = (int64_t)queries;
    for (size_t index = 0; index < queries; ++index) {
        const size_t offset = query_base + 3 * index;
        const int64_t opcode = input[offset];
        const size_t node = (size_t)input[offset + 1];
        const int64_t argument = input[offset + 2];
        int64_t answer;
        if (opcode == 0) {
            answer = (int64_t)decoded_degrees[node];
        } else if (opcode == 1) {
            answer = -1;
            if (node != 0) {
                for (size_t candidate = 0; candidate < nodes; ++candidate) {
                    if (rank_prefix[candidate + 1] >= node) {
                        answer = (int64_t)candidate;
                        break;
                    }
                }
            }
        } else {
            const size_t first_child = 1 + rank_prefix[node];
            answer = (size_t)argument < decoded_degrees[node]
                ? (int64_t)(first_child + (size_t)argument) : -1;
        }
        words[4 + index] = answer;
    }

    const size_t output_words = 4 + queries;
    const size_t output_bytes = output_words * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < output_words; ++index)
        write_i64_le(output, index, words[index]);
    return (int64_t)output_bytes;
}
