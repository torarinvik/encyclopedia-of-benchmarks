#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NODES = 8;
constexpr std::size_t MAX_OPERATIONS = 24;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 98;
constexpr std::size_t MAX_OUTPUT_WORDS = 144;

void push_word(std::int64_t *words, std::size_t &count, std::int64_t value)
{
    words[count++] = value;
}

void push_record(std::int64_t *words, std::size_t &count, std::int64_t opcode,
                 const std::int64_t *payload, std::size_t payload_count)
{
    push_word(words, count, opcode);
    push_word(words, count, static_cast<std::int64_t>(payload_count));
    for (std::size_t index = 0; index < payload_count; ++index)
        push_word(words, count, payload[index]);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t undirected_adjacency_list_graph(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + 4 * operation_count) return -1;

    std::int64_t words[MAX_OUTPUT_WORDS]{};
    std::size_t word_count = 0;
    std::int64_t edge_weights[MAX_NODES][MAX_NODES]{};
    bool has_edge[MAX_NODES][MAX_NODES]{};
    std::size_t node_count = 0;

    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const std::size_t base = 1 + 4 * operation_index;
        const std::int64_t opcode = input[base];
        const std::int64_t first = input[base + 1];
        const std::int64_t second = input[base + 2];
        const std::int64_t third = input[base + 3];
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
        } else if (first < INT32_MIN || first > INT32_MAX ||
                   second < INT32_MIN || second > INT32_MAX || third != 0) {
            return -1;
        }

        if (opcode == 0) {
            if (node_count >= MAX_NODES) return -1;
            const std::int64_t payload[] = {static_cast<std::int64_t>(node_count)};
            push_record(words, word_count, opcode, payload, 1);
            ++node_count;
        } else if (opcode == 1) {
            bool added = false;
            if (first >= 0 && static_cast<std::uint64_t>(first) < node_count &&
                second >= 0 && static_cast<std::uint64_t>(second) < node_count &&
                !has_edge[first][second]) {
                has_edge[first][second] = true;
                has_edge[second][first] = true;
                edge_weights[first][second] = third;
                edge_weights[second][first] = third;
                added = true;
            }
            const std::int64_t payload[] = {added ? 1 : 0};
            push_record(words, word_count, opcode, payload, 1);
        } else if (opcode == 2) {
            if (first < 0 || static_cast<std::uint64_t>(first) >= node_count) return -1;
            std::int64_t payload[MAX_NODES + 1];
            std::size_t neighbor_count = 0;
            for (std::size_t neighbor = 0; neighbor < node_count; ++neighbor)
                if (has_edge[first][neighbor]) payload[neighbor_count++] = static_cast<std::int64_t>(neighbor);
            for (std::size_t index = neighbor_count; index > 0; --index)
                payload[index] = payload[index - 1];
            payload[0] = static_cast<std::int64_t>(neighbor_count);
            push_record(words, word_count, opcode, payload, neighbor_count + 1);
        } else if (opcode == 3) {
            if (first < 0 || static_cast<std::uint64_t>(first) >= node_count) return -1;
            const bool present = second >= 0 && static_cast<std::uint64_t>(second) < node_count &&
                                has_edge[first][second];
            const std::int64_t payload[] = {present ? 1 : 0,
                                             present ? edge_weights[first][second] : 0};
            push_record(words, word_count, opcode, payload, 2);
        } else {
            const std::int64_t payload[] = {static_cast<std::int64_t>(node_count)};
            push_record(words, word_count, opcode, payload, 1);
        }
    }

    const std::size_t output_bytes = word_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < word_count; ++index)
        store_i64_le(output, index * 8, words[index]);
    return static_cast<std::int64_t>(output_bytes);
}
