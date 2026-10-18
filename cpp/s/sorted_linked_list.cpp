#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_initial_count = 16;
constexpr std::size_t max_input_length = 20;
constexpr std::size_t max_output_words = 18;

struct ListNode { std::int32_t value; std::int32_t next; };

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t sorted_linked_list(
    const std::int64_t* input, std::size_t input_length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || input_length < 3 || input_length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_initial_count)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (input_length != count + 3) return -1;

    ListNode nodes[max_initial_count + 1];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX || (index > 0 && input[index] >= value)) return -1;
        nodes[index] = {static_cast<std::int32_t>(value), index + 1 < count ? static_cast<std::int32_t>(index + 1) : -1};
    }
    const auto operation_value = input[count + 1];
    const auto key_value = input[count + 2];
    if (operation_value < 0 || operation_value > 2 || key_value < INT32_MIN || key_value > INT32_MAX) return -1;
    const auto operation = static_cast<int>(operation_value);
    const auto key = static_cast<std::int32_t>(key_value);
    std::int32_t head = count == 0 ? -1 : 0;
    std::int32_t tail = count == 0 ? -1 : static_cast<std::int32_t>(count - 1);

    if (operation == 0) {
        for (auto node = head; node >= 0; node = nodes[node].next) if (nodes[node].value == key) return -1;
    }

    std::int64_t staged[max_output_words]{};
    std::size_t word_count = 0;
    if (operation == 0) {
        const auto new_node = static_cast<std::int32_t>(count);
        nodes[new_node] = {key, -1};
        if (head < 0) { head = new_node; tail = new_node; }
        else if (key < nodes[head].value) { nodes[new_node].next = head; head = new_node; }
        else if (key > nodes[tail].value) { nodes[tail].next = new_node; tail = new_node; }
        else {
            auto previous = head;
            while (nodes[previous].next >= 0 && nodes[nodes[previous].next].value < key) previous = nodes[previous].next;
            nodes[new_node].next = nodes[previous].next;
            nodes[previous].next = new_node;
            if (nodes[new_node].next < 0) tail = new_node;
        }
        staged[word_count++] = static_cast<std::int64_t>(count + 1);
        for (auto node = head; node >= 0; node = nodes[node].next) staged[word_count++] = nodes[node].value;
    } else if (operation == 1) {
        std::int64_t found = 0;
        for (auto node = head; node >= 0; node = nodes[node].next) if (nodes[node].value == key) { found = 1; break; }
        staged[word_count++] = found;
    } else {
        std::int64_t deleted = 0;
        if (head >= 0 && nodes[head].value == key) {
            head = nodes[head].next;
            if (head < 0) tail = -1;
            deleted = 1;
        } else {
            auto previous = head;
            while (previous >= 0 && nodes[previous].next >= 0) {
                const auto candidate = nodes[previous].next;
                if (nodes[candidate].value == key) {
                    nodes[previous].next = nodes[candidate].next;
                    if (tail == candidate) tail = previous;
                    deleted = 1;
                    break;
                }
                previous = candidate;
            }
        }
        staged[word_count++] = deleted;
        std::size_t remaining = 0;
        for (auto node = head; node >= 0; node = nodes[node].next) ++remaining;
        staged[word_count++] = static_cast<std::int64_t>(remaining);
        for (auto node = head; node >= 0; node = nodes[node].next) staged[word_count++] = nodes[node].value;
    }

    const auto output_bytes = word_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < word_count; ++index) put_i64_le(output, index * 8, staged[index]);
    return static_cast<std::int64_t>(output_bytes);
}
