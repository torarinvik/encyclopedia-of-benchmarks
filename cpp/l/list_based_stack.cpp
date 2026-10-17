#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_initial_items = 32;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input_length = 162;
constexpr std::size_t max_stack_size = max_initial_items + max_operations;
constexpr std::size_t max_output_bytes = 16 * max_operations;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t list_based_stack(const std::int64_t* input,
                                          std::size_t length,
                                          std::uint8_t* output,
                                          std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;

    const auto raw_initial_count = input[0];
    if (raw_initial_count < 0 || raw_initial_count > static_cast<std::int64_t>(max_initial_items))
        return -1;
    const auto initial_count = static_cast<std::size_t>(raw_initial_count);
    const auto operation_count_index = 1 + initial_count;
    if (operation_count_index >= length) return -1;

    std::array<std::int64_t, max_initial_items> initial_items{};
    for (std::size_t index = 0; index < initial_count; ++index) {
        const auto value = input[1 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        initial_items[index] = value;
    }

    const auto raw_operation_count = input[operation_count_index];
    if (raw_operation_count < 0 || raw_operation_count > static_cast<std::int64_t>(max_operations))
        return -1;
    const auto operation_count = static_cast<std::size_t>(raw_operation_count);
    std::array<std::int64_t, max_operations> opcodes{};
    std::array<std::int64_t, max_operations> arguments{};
    auto cursor = operation_count_index + 1;
    auto validated_size = initial_count;
    for (std::size_t index = 0; index < operation_count; ++index) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1 || opcode == 5) {
            if (cursor >= length) return -1;
            const auto value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            arguments[index] = value;
            if (opcode == 1) ++validated_size;
        } else if (opcode == 2 || opcode == 3) {
            if (validated_size == 0) return -1;
            if (opcode == 2) --validated_size;
        } else if (opcode == 4) {
            // Count leaves the stack unchanged.
        } else if (opcode == 6) {
            validated_size = 0;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    std::array<std::int64_t, max_stack_size> stack{};
    auto stack_size = initial_count;
    for (std::size_t index = 0; index < initial_count; ++index)
        stack[index] = initial_items[index];

    std::array<std::uint8_t, max_output_bytes> buffer{};
    std::size_t written = 0;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto opcode = opcodes[index];
        std::int64_t result = 0;
        if (opcode == 1) {
            stack[stack_size++] = arguments[index];
        } else if (opcode == 2) {
            result = stack[--stack_size];
        } else if (opcode == 3) {
            result = stack[stack_size - 1];
        } else if (opcode == 4) {
            result = static_cast<std::int64_t>(stack_size);
        } else if (opcode == 5) {
            for (std::size_t item = 0; item < stack_size; ++item) {
                if (stack[item] == arguments[index]) {
                    result = 1;
                    break;
                }
            }
        } else {
            stack_size = 0;
        }
        put_i64_le(buffer.data(), written, opcode);
        put_i64_le(buffer.data(), written + 8, result);
        written += 16;
    }

    if (output == nullptr || capacity < written) return -2;
    for (std::size_t index = 0; index < written; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(written);
}
