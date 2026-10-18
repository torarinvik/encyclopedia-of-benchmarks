/* Bounded replay of the indexed undirected weighted adjacency-list graph. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 8
#define MAX_OPERATIONS 24
#define MAX_PARSEABLE_INPUT_LENGTH 98
#define MAX_OUTPUT_WORDS 144

static void push_word(int64_t *words, size_t *count, int64_t value)
{
    words[*count] = value;
    ++*count;
}

static void push_record(int64_t *words, size_t *count, int64_t opcode,
                        const int64_t *payload, size_t payload_count)
{
    push_word(words, count, opcode);
    push_word(words, count, (int64_t)payload_count);
    for (size_t index = 0; index < payload_count; ++index)
        push_word(words, count, payload[index]);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t undirected_adjacency_list_graph(const int64_t *input, size_t input_length,
                                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];
    if (input_length != 1 + 4 * operation_count) return -1;

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 0;
    int64_t edge_weights[MAX_NODES][MAX_NODES] = {{0}};
    uint8_t has_edge[MAX_NODES][MAX_NODES] = {{0}};
    size_t node_count = 0;

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const size_t base = 1 + 4 * operation_index;
        const int64_t opcode = input[base];
        const int64_t first = input[base + 1];
        const int64_t second = input[base + 2];
        const int64_t third = input[base + 3];
        if (opcode < 0 || opcode > 4) return -1;

        if (opcode == 0 || opcode == 4) {
            if (first != 0 || second != 0 || third != 0) return -1;
        } else if (opcode == 1) {
            if (first < INT32_MIN || first > INT32_MAX ||
                second < INT32_MIN || second > INT32_MAX ||
                third < INT32_MIN || third > INT32_MAX) return -1;
        } else if (opcode == 2) {
            if (first < INT32_MIN || first > INT32_MAX || second != 0 || third != 0)
                return -1;
        } else {
            if (first < INT32_MIN || first > INT32_MAX ||
                second < INT32_MIN || second > INT32_MAX || third != 0) return -1;
        }

        if (opcode == 0) {
            if (node_count >= MAX_NODES) return -1;
            const int64_t payload[] = {(int64_t)node_count};
            push_record(words, &word_count, opcode, payload, 1);
            ++node_count;
        } else if (opcode == 1) {
            int added = 0;
            if (first >= 0 && (uint64_t)first < node_count &&
                second >= 0 && (uint64_t)second < node_count &&
                !has_edge[first][second]) {
                has_edge[first][second] = 1;
                has_edge[second][first] = 1;
                edge_weights[first][second] = third;
                edge_weights[second][first] = third;
                added = 1;
            }
            const int64_t payload[] = {added};
            push_record(words, &word_count, opcode, payload, 1);
        } else if (opcode == 2) {
            if (first < 0 || (uint64_t)first >= node_count) return -1;
            int64_t payload[MAX_NODES + 1];
            size_t neighbor_count = 0;
            for (size_t neighbor = 0; neighbor < node_count; ++neighbor) {
                if (has_edge[first][neighbor]) payload[neighbor_count++] = (int64_t)neighbor;
            }
            for (size_t index = neighbor_count; index > 0; --index)
                payload[index] = payload[index - 1];
            payload[0] = (int64_t)neighbor_count;
            push_record(words, &word_count, opcode, payload, neighbor_count + 1);
        } else if (opcode == 3) {
            if (first < 0 || (uint64_t)first >= node_count) return -1;
            const int present = second >= 0 && (uint64_t)second < node_count &&
                                has_edge[first][second];
            const int64_t payload[] = {present, present ? edge_weights[first][second] : 0};
            push_record(words, &word_count, opcode, payload, 2);
        } else {
            const int64_t payload[] = {(int64_t)node_count};
            push_record(words, &word_count, opcode, payload, 1);
        }
    }

    const size_t output_bytes = word_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index)
        store_i64_le(output, index * 8, words[index]);
    return (int64_t)output_bytes;
}
