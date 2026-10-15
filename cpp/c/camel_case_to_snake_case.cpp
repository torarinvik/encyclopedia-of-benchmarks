#include <cstddef>
#include <cstdint>

extern "C" std::int64_t camel_case_to_snake_case(const std::int64_t* input,
                                                  std::size_t length,
                                                  std::uint8_t* output,
                                                  std::size_t capacity) noexcept {
    if (length == 0 || length > 256 || input == nullptr) return -1;

    std::size_t output_length = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = input[i];
        if (value >= 'A' && value <= 'Z') {
            if (i > 0) ++output_length;
        } else if (value < 'a' || value > 'z') {
            return -1;
        }
        ++output_length;
    }
    if (capacity < output_length || output == nullptr) return -2;

    std::size_t position = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = input[i];
        if (value >= 'A' && value <= 'Z') {
            if (i > 0) output[position++] = static_cast<std::uint8_t>('_');
            output[position++] = static_cast<std::uint8_t>(value + ('a' - 'A'));
        } else {
            output[position++] = static_cast<std::uint8_t>(value);
        }
    }
    return static_cast<std::int64_t>(output_length);
}
