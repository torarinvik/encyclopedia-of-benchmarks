#include <cstddef>
#include <cstdint>
#include <climits>

extern "C" std::int64_t single_bit_manipulation_operations(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 3) return -1;
    const auto opcode = input[0], number = input[1], position = input[2];
    if (opcode < 0 || opcode > 5 || number < INT32_MIN || number > INT32_MAX) return -1;
    if (opcode == 5) {
        if (position != -1) return -1;
        return number & (number - 1);
    }
    if (position < 0 || position > 31) return -1;
    const std::int64_t mask = std::int64_t{1} << position;
    switch (opcode) {
        case 0: return number | mask;
        case 1: return number & ~mask;
        case 2: return number ^ mask;
        case 3: return static_cast<std::int64_t>((static_cast<std::uint64_t>(number) >> position) & 1u);
        case 4: return (number & mask) != 0;
        default: return -1;
    }
}
