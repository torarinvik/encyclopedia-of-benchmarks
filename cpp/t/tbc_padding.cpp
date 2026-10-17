#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_bytes = 256;
void write_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[position + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tbc_padding(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_bytes + 3) return -1;
    const auto operation = input[0], offset_value = input[1], count_value = input[2];
    if (operation < 0 || operation > 2 || count_value < 0 || count_value > static_cast<std::int64_t>(max_bytes) ||
        length != static_cast<std::size_t>(count_value) + 3) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if ((operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
        (operation != 0 && offset_value != 0) || (operation == 2 && count == 0)) return -1;
    for (std::size_t i = 0; i < count; ++i) if (input[3 + i] < 0 || input[3 + i] > 255) return -1;

    if (operation == 0) {
        const auto offset = static_cast<std::size_t>(offset_value);
        const auto previous = input[offset > 0 ? offset + 2 : count + 2];
        const auto code = (previous & 1) == 0 ? std::uint8_t(0xff) : std::uint8_t(0x00);
        const auto needed = 8 + count;
        if (output == nullptr || capacity < needed) return -2;
        write_i64_le(output, 0, static_cast<std::int64_t>(count - offset));
        for (std::size_t i = 0; i < count; ++i) output[8 + i] = i >= offset ? code : static_cast<std::uint8_t>(input[3 + i]);
        return static_cast<std::int64_t>(needed);
    }
    if (operation == 1) {
        std::size_t survivor_count = count;
        std::uint8_t code = 0;
        if (count > 0) {
            code = (input[2 + count] & 1) == 0 ? 0x00 : 0xff;
            while (survivor_count > 0 && input[2 + survivor_count] == code) --survivor_count;
        }
        if (output == nullptr || capacity < survivor_count) return -2;
        for (std::size_t i = 0; i < survivor_count; ++i) output[i] = static_cast<std::uint8_t>(input[3 + i]);
        return static_cast<std::int64_t>(survivor_count);
    }
    const auto terminal = input[2 + count];
    if (terminal != 0 && terminal != 255) return -1;
    std::size_t padding_count = 0;
    while (padding_count < count && input[2 + count - padding_count] == terminal) ++padding_count;
    if (output == nullptr || capacity < 8) return -2;
    write_i64_le(output, 0, static_cast<std::int64_t>(padding_count));
    return 8;
}
