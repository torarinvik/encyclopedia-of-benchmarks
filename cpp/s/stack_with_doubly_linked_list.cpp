#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPERATIONS = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 129;
constexpr std::size_t MAX_OUTPUT_BYTES = 1536;

struct Node {
    std::int64_t value;
    std::size_t next;
    std::size_t previous;
};

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void write_record(std::uint8_t *output, std::size_t offset,
                  std::int64_t opcode, std::int64_t tag, std::int64_t value) {
    write_i64_le(output, offset, opcode);
    write_i64_le(output, offset + 8, tag);
    write_i64_le(output, offset + 16, value);
}
}

extern "C" std::int64_t stack_with_doubly_linked_list(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > 64) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t opcodes[MAX_OPERATIONS]{};
    std::int64_t arguments[MAX_OPERATIONS]{};
    std::size_t cursor = 1;
    for (std::size_t i = 0; i < count; ++i) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        opcodes[i] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const auto value = input[cursor++];
            if (value < -2147483648LL || value > 2147483647LL) return -1;
            arguments[i] = value;
        } else if (opcode < 2 || opcode > 4) return -1;
    }
    if (cursor != length) return -1;

    Node nodes[MAX_OPERATIONS + 1]{};
    std::size_t node_count = 0, head = 0, written = 0;
    std::uint8_t buffer[MAX_OUTPUT_BYTES]{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto opcode = opcodes[i];
        std::int64_t tag = 2, value = 0;
        if (opcode == 1) {
            const auto node_id = ++node_count;
            nodes[node_id] = Node{arguments[i], head, 0};
            if (head != 0) nodes[head].previous = node_id;
            head = node_id;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = nodes[head].value;
                head = nodes[head].next;
                if (head != 0) nodes[head].previous = 0;
            }
        } else if (opcode == 3) {
            if (head != 0) { tag = 0; value = nodes[head].value; }
        } else {
            tag = 0;
            for (auto node = head; node != 0; node = nodes[node].next) ++value;
        }
        write_record(buffer, written, opcode, tag, value);
        written += 24;
    }
    if (output == nullptr || capacity < written) return -2;
    for (std::size_t i = 0; i < written; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(written);
}
