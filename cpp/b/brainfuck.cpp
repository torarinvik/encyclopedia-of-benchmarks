/* Interpret a bounded Brainfuck byte program with portable limits. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_program = 2048;
constexpr std::size_t max_input = 1024;
constexpr std::size_t max_output = 8192;
constexpr std::size_t max_steps = 100000;
constexpr std::size_t tape_cells = 257;
}

extern "C" std::int64_t brainfuck(const std::int64_t *values, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > max_program + max_input + 2) return -2;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_program)) return -2;
    const auto program_length = static_cast<std::size_t>(values[0]);
    const auto input_length_index = program_length + 1;
    if (length <= input_length_index || values[input_length_index] < 0
        || values[input_length_index] > static_cast<std::int64_t>(max_input)) return -2;
    const auto input_length = static_cast<std::size_t>(values[input_length_index]);
    if (length != program_length + input_length + 2) return -2;

    std::int32_t matching[max_program];
    std::size_t openings[max_program];
    for (std::size_t index = 0; index < program_length; ++index) {
        matching[index] = -1;
        const auto byte = values[index + 1];
        if (byte < 32 || byte > 126) return -2;
    }
    std::size_t depth = 0;
    for (std::size_t index = 0; index < program_length; ++index) {
        const auto byte = values[index + 1];
        if (byte == '[') {
            openings[depth++] = index;
        } else if (byte == ']') {
            if (depth == 0) return -2;
            const auto opening = openings[--depth];
            matching[opening] = static_cast<std::int32_t>(index);
            matching[index] = static_cast<std::int32_t>(opening);
        }
    }
    if (depth != 0) return -2;
    for (std::size_t index = 0; index < input_length; ++index) {
        const auto byte = values[input_length_index + 1 + index];
        if (byte < 0 || byte > 255) return -2;
    }

    std::uint8_t tape[tape_cells]{};
    std::uint8_t scratch[max_output];
    auto data_pointer = tape_cells / 2;
    std::size_t input_index = 0, instruction = 0, steps = 0, output_length = 0;
    while (instruction < program_length) {
        if (++steps > max_steps) return -2;
        const auto command = values[instruction + 1];
        if (command == '.') {
            if (output_length == max_output) return -2;
            scratch[output_length++] = tape[data_pointer];
        } else if (command == ',') {
            tape[data_pointer] = input_index < input_length
                ? static_cast<std::uint8_t>(values[input_length_index + 1 + input_index++]) : 0;
        } else if (command == '>') {
            if (++data_pointer >= tape_cells) return -2;
        } else if (command == '<') {
            if (data_pointer == 0) return -2;
            --data_pointer;
        } else if (command == '+') {
            tape[data_pointer] = static_cast<std::uint8_t>(tape[data_pointer] + 1u);
        } else if (command == '-') {
            tape[data_pointer] = static_cast<std::uint8_t>(tape[data_pointer] - 1u);
        } else if (command == '[' && tape[data_pointer] == 0) {
            instruction = static_cast<std::size_t>(matching[instruction]);
        } else if (command == ']' && tape[data_pointer] != 0) {
            instruction = static_cast<std::size_t>(matching[instruction]);
        }
        ++instruction;
    }
    if (output_length > output_capacity || (output_length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = scratch[index];
    return static_cast<std::int64_t>(output_length);
}
