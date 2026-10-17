#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPERATIONS = 256;
constexpr std::size_t MAX_INPUT_VALUES = 1 + 2 * MAX_OPERATIONS;
constexpr std::size_t MAX_OUTPUT_BYTES = (1 + 3 * MAX_OPERATIONS) * 8;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t min_stack(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto count = static_cast<std::size_t>(count_value);

    std::int64_t opcodes[MAX_OPERATIONS]{}, operands[MAX_OPERATIONS]{};
    std::size_t position = 1, query_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (position >= length) return -1;
        const auto opcode = input[position++];
        std::int64_t operand = 0;
        if (opcode == 0) {
            if (position >= length) return -1;
            operand = input[position++];
            if (operand < -2'147'483'648LL || operand > 2'147'483'647LL) return -1;
        } else if (opcode == 2 || opcode == 3) {
            ++query_count;
        } else if (opcode != 1) {
            return -1;
        }
        opcodes[i] = opcode;
        operands[i] = operand;
    }
    if (position != length) return -1;

    const auto needed = (1 + 3 * query_count) * 8;
    if (output == nullptr || capacity < needed) return -2;

    std::uint8_t buffer[MAX_OUTPUT_BYTES]{};
    write_i64_le(buffer, 0, static_cast<std::int64_t>(query_count));
    std::int64_t stack_values[MAX_OPERATIONS]{}, stack_minima[MAX_OPERATIONS]{};
    std::size_t depth = 0, record = 1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto opcode = opcodes[i];
        if (opcode == 0) {
            const auto value = operands[i];
            stack_values[depth] = value;
            stack_minima[depth] = depth == 0 || value < stack_minima[depth - 1]
                ? value : stack_minima[depth - 1];
            ++depth;
        } else if (opcode == 1) {
            if (depth > 0) --depth;
        } else {
            std::int64_t exception_flag = 0, value = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else if (opcode == 2) {
                value = stack_values[depth - 1];
            } else {
                value = stack_minima[depth - 1];
            }
            write_i64_le(buffer, record * 8, opcode);
            write_i64_le(buffer, (record + 1) * 8, exception_flag);
            write_i64_le(buffer, (record + 2) * 8, value);
            record += 3;
        }
    }
    for (std::size_t i = 0; i < needed; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(needed);
}
