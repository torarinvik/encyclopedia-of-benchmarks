#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input_length = 129;
constexpr std::size_t max_output_bytes = 1536;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void put_record(std::uint8_t* output, std::size_t offset,
                std::int64_t opcode, std::int64_t tag, std::int64_t value) {
    put_i64_le(output, offset, opcode);
    put_i64_le(output, offset + 8, tag);
    put_i64_le(output, offset + 16, value);
}
} // namespace

extern "C" std::int64_t linked_stack(const std::int64_t* input, std::size_t length,
                                     std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(raw_count);
    std::array<std::int64_t, max_operations> opcodes{};
    std::array<std::int64_t, max_operations> arguments{};
    std::size_t cursor = 1;
    for (std::size_t index = 0; index < operation_count; ++index) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const auto value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            arguments[index] = value;
        } else if (opcode < 2 || opcode > 4) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    std::array<std::int64_t, max_operations + 1> node_values{};
    std::array<std::size_t, max_operations + 1> below{};
    std::size_t node_count = 0, head = 0, written = 0;
    std::array<std::uint8_t, max_output_bytes> buffer{};
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto opcode = opcodes[index];
        std::int64_t tag = 2, value = 0;
        if (opcode == 1) {
            const auto node = ++node_count;
            node_values[node] = arguments[index];
            below[node] = head;
            head = node;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
            }
        } else if (opcode == 3) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
                head = below[head];
            }
        } else {
            tag = 1;
            value = head == 0;
        }
        put_record(buffer.data(), written, opcode, tag, value);
        written += 24;
    }

    if (output == nullptr || capacity < written) return -2;
    for (std::size_t index = 0; index < written; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(written);
}
