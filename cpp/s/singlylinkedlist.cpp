#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_parseable_input_values = 227;
constexpr std::size_t max_initial_nodes = 32;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_list_nodes = 96;
constexpr std::size_t max_output_words = 226;
constexpr std::size_t max_output_bytes = 1808;
constexpr std::int64_t min_value = -1000000;
constexpr std::int64_t max_value = 1000000;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;

struct ListNode {
    std::int64_t value;
    int next;
};

int allocate_node(std::array<ListNode, max_list_nodes> &nodes,
                  std::size_t &allocated, std::int64_t value) noexcept
{
    const int index = static_cast<int>(allocated++);
    nodes[static_cast<std::size_t>(index)].value = value;
    nodes[static_cast<std::size_t>(index)].next = -1;
    return index;
}

void append_result(std::array<std::int64_t, 2 * max_operations> &results,
                   std::size_t &count, std::int64_t success,
                   std::int64_t value) noexcept
{
    results[count++] = success;
    results[count++] = value;
}

void reverse_list(std::array<ListNode, max_list_nodes> &nodes,
                  int &head, int &tail) noexcept
{
    int previous = -1;
    int current = head;
    tail = head;
    while (current != -1) {
        const int next = nodes[static_cast<std::size_t>(current)].next;
        nodes[static_cast<std::size_t>(current)].next = previous;
        previous = current;
        current = next;
    }
    head = previous;
}

void reverse_range(std::array<ListNode, max_list_nodes> &nodes,
                   int &head, int &tail, std::size_t list_count,
                   std::size_t left, std::size_t right) noexcept
{
    int before = -1;
    int segment_start = head;
    for (std::size_t index = 0; index < left; ++index) {
        before = segment_start;
        segment_start = nodes[static_cast<std::size_t>(segment_start)].next;
    }

    int previous = -1;
    int current = segment_start;
    for (std::size_t index = left; index <= right; ++index) {
        const int next = nodes[static_cast<std::size_t>(current)].next;
        nodes[static_cast<std::size_t>(current)].next = previous;
        previous = current;
        current = next;
    }
    nodes[static_cast<std::size_t>(segment_start)].next = current;
    if (before == -1) head = previous;
    else nodes[static_cast<std::size_t>(before)].next = previous;
    if (right + 1 == list_count) tail = segment_start;
}

std::int64_t remove_head(std::array<ListNode, max_list_nodes> &nodes,
                         int &head, int &tail, std::size_t &list_count) noexcept
{
    const int removed = head;
    const std::int64_t value = nodes[static_cast<std::size_t>(removed)].value;
    head = nodes[static_cast<std::size_t>(removed)].next;
    --list_count;
    if (list_count == 0) tail = -1;
    return value;
}

std::int64_t remove_tail(std::array<ListNode, max_list_nodes> &nodes,
                         int &head, int &tail, std::size_t &list_count) noexcept
{
    if (list_count == 1) return remove_head(nodes, head, tail, list_count);
    int previous = head;
    while (nodes[static_cast<std::size_t>(previous)].next != tail)
        previous = nodes[static_cast<std::size_t>(previous)].next;
    const int removed = tail;
    const std::int64_t value = nodes[static_cast<std::size_t>(removed)].value;
    nodes[static_cast<std::size_t>(previous)].next = -1;
    tail = previous;
    --list_count;
    return value;
}

void store_little_endian_i64(std::uint8_t *output, std::int64_t value) noexcept
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t singlylinkedlist(const std::int64_t *input,
                                          std::size_t input_length,
                                          std::uint8_t *output,
                                          std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 2 ||
        input_length > max_parseable_input_values) return invalid_result;

    const std::int64_t initial_count_value = input[0];
    const std::int64_t operation_count_value = input[1];
    if (initial_count_value < 0 ||
        initial_count_value > static_cast<std::int64_t>(max_initial_nodes) ||
        operation_count_value < 0 ||
        operation_count_value > static_cast<std::int64_t>(max_operations))
        return invalid_result;

    const std::size_t initial_count = static_cast<std::size_t>(initial_count_value);
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    std::size_t cursor = 2;
    if (input_length < cursor + initial_count) return invalid_result;

    std::array<ListNode, max_list_nodes> nodes{};
    std::size_t allocated = 0;
    std::size_t list_count = 0;
    int head = -1;
    int tail = -1;
    for (std::size_t index = 0; index < initial_count; ++index) {
        const std::int64_t value = input[cursor++];
        if (value < min_value || value > max_value) return invalid_result;
        const int node = allocate_node(nodes, allocated, value);
        if (head == -1) head = node;
        else nodes[static_cast<std::size_t>(tail)].next = node;
        tail = node;
        ++list_count;
    }

    std::array<std::int64_t, 2 * max_operations> operation_results{};
    std::size_t result_word_count = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= input_length) return invalid_result;
        const std::int64_t opcode = input[cursor++];
        std::size_t arity;
        switch (opcode) {
            case 0:
            case 1:
            case 4: arity = 1; break;
            case 2:
            case 3:
            case 5: arity = 0; break;
            case 6: arity = 2; break;
            default: return invalid_result;
        }
        if (cursor + arity > input_length) return invalid_result;
        const std::int64_t first = arity >= 1 ? input[cursor] : 0;
        const std::int64_t second = arity == 2 ? input[cursor + 1] : 0;
        cursor += arity;

        if (opcode == 0 || opcode == 1) {
            if (first < min_value || first > max_value ||
                list_count >= max_list_nodes || allocated >= max_list_nodes)
                return invalid_result;
            const int node = allocate_node(nodes, allocated, first);
            if (opcode == 0) {
                nodes[static_cast<std::size_t>(node)].next = head;
                head = node;
                if (list_count == 0) tail = node;
            } else {
                if (list_count == 0) head = node;
                else nodes[static_cast<std::size_t>(tail)].next = node;
                tail = node;
            }
            ++list_count;
            append_result(operation_results, result_word_count, 1, 0);
        } else if (opcode == 2) {
            if (list_count == 0)
                append_result(operation_results, result_word_count, 0, 0);
            else
                append_result(operation_results, result_word_count, 1,
                              remove_head(nodes, head, tail, list_count));
        } else if (opcode == 3) {
            if (list_count == 0)
                append_result(operation_results, result_word_count, 0, 0);
            else
                append_result(operation_results, result_word_count, 1,
                              remove_tail(nodes, head, tail, list_count));
        } else if (opcode == 4) {
            if (list_count == 0) {
                if (first != 1) return invalid_result;
                append_result(operation_results, result_word_count, 0, 0);
            } else {
                if (first < 1 || first > static_cast<std::int64_t>(list_count) + 1)
                    return invalid_result;
                std::size_t target = static_cast<std::size_t>(first - 1);
                if (target >= list_count) target = list_count - 1;
                std::int64_t value;
                if (target == 0) {
                    value = remove_head(nodes, head, tail, list_count);
                } else if (target + 1 == list_count) {
                    value = remove_tail(nodes, head, tail, list_count);
                } else {
                    int previous = head;
                    for (std::size_t index = 1; index < target; ++index)
                        previous = nodes[static_cast<std::size_t>(previous)].next;
                    const int removed = nodes[static_cast<std::size_t>(previous)].next;
                    value = nodes[static_cast<std::size_t>(removed)].value;
                    nodes[static_cast<std::size_t>(previous)].next =
                        nodes[static_cast<std::size_t>(removed)].next;
                    --list_count;
                }
                append_result(operation_results, result_word_count, 1, value);
            }
        } else if (opcode == 5) {
            if (list_count > 1) reverse_list(nodes, head, tail);
            append_result(operation_results, result_word_count, 1, 0);
        } else {
            if (first < 1 || second < first ||
                second > static_cast<std::int64_t>(list_count)) return invalid_result;
            reverse_range(nodes, head, tail, list_count,
                          static_cast<std::size_t>(first - 1),
                          static_cast<std::size_t>(second - 1));
            append_result(operation_results, result_word_count, 1, 0);
        }
    }
    if (cursor != input_length) return invalid_result;

    std::array<std::int64_t, max_output_words> output_words{};
    std::size_t output_word_count = 0;
    output_words[output_word_count++] = static_cast<std::int64_t>(list_count);
    int current = head;
    std::size_t traversed = 0;
    while (current != -1 && traversed < list_count) {
        output_words[output_word_count++] = nodes[static_cast<std::size_t>(current)].value;
        current = nodes[static_cast<std::size_t>(current)].next;
        ++traversed;
    }
    if (traversed != list_count || current != -1) return invalid_result;
    output_words[output_word_count++] = static_cast<std::int64_t>(operation_count);
    for (std::size_t index = 0; index < result_word_count; ++index)
        output_words[output_word_count++] = operation_results[index];

    const std::size_t output_bytes = output_word_count * 8;
    std::array<std::uint8_t, max_output_bytes> encoded{};
    for (std::size_t index = 0; index < output_word_count; ++index)
        store_little_endian_i64(encoded.data() + index * 8, output_words[index]);

    if (output == nullptr || output_capacity < output_bytes) return output_error;
    std::memcpy(output, encoded.data(), output_bytes);
    return static_cast<std::int64_t>(output_bytes);
}
