#include <cstddef>
#include <cstdint>

extern "C" std::int64_t snake_case_to_camel_pascal_case(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 257) return -1;
    if (input[0] != 0 && input[0] != 1) return -1;

    const std::size_t input_length = length - 1;
    std::size_t output_length = 0;
    for (std::size_t i = 0; i < input_length; ++i) {
        const auto value = input[i + 1];
        if (value == '_') {
            if (i == 0 || i + 1 == input_length || input[i] == '_') return -1;
        } else if (!((value >= 'a' && value <= 'z') || (value >= '0' && value <= '9'))) {
            return -1;
        } else {
            ++output_length;
        }
    }
    if (capacity < output_length || output == nullptr) return -2;

    std::size_t position = 0;
    bool capitalize = input[0] == 1;
    for (std::size_t i = 0; i < input_length; ++i) {
        auto value = input[i + 1];
        if (value == '_') {
            capitalize = true;
            continue;
        }
        if (capitalize && value >= 'a' && value <= 'z') value -= 'a' - 'A';
        output[position++] = static_cast<std::uint8_t>(value);
        capitalize = false;
    }
    return static_cast<std::int64_t>(output_length);
}
