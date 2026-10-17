#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_input_length = max_text_length + 1;
constexpr std::size_t max_parseable_input_length = max_input_length + 2;
constexpr std::size_t max_output_bytes = 4;

bool is_ascii_letter(std::int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

std::int64_t digit_for(std::int64_t value)
{
    if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
    if (value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u' || value == 'y') return 0;
    if (value == 'h' || value == 'w') return 8;
    if (value == 'b' || value == 'f' || value == 'p' || value == 'v') return 1;
    if (value == 'c' || value == 'g' || value == 'j' || value == 'k' || value == 'q' || value == 's' ||
        value == 'x' || value == 'z') return 2;
    if (value == 'd' || value == 't') return 3;
    if (value == 'l') return 4;
    if (value == 'm' || value == 'n') return 5;
    if (value == 'r') return 6;
    return -1;
}
}

extern "C" std::int64_t soundex_encoder(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity)
{
    if (length < 1 || length > max_parseable_input_length || values == nullptr) return -1;
    const auto text_length = values[0];
    if (text_length < 1 || text_length > max_text_length || length > max_input_length ||
        length != static_cast<std::size_t>(text_length) + 1) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (!is_ascii_letter(values[index])) return -1;

    std::int64_t mapped[max_text_length];
    std::size_t mapped_count = 0;
    for (std::size_t index = 1; index < length; ++index) {
        auto letter = values[index];
        if (letter >= 'A' && letter <= 'Z') letter += 'a' - 'A';
        if (letter == 'h' || letter == 'w') continue;
        const auto digit = digit_for(letter);
        if (mapped_count == 0 || mapped[mapped_count - 1] != digit)
            mapped[mapped_count++] = digit;
    }

    std::size_t code_count = 0;
    for (std::size_t index = 0; index < mapped_count; ++index)
        if (mapped[index] != 0) mapped[code_count++] = mapped[index];
    if (code_count == 0) return -1;

    auto first_letter = values[1];
    if (first_letter >= 'A' && first_letter <= 'Z') first_letter += 'a' - 'A';
    std::size_t start = 0;
    if (mapped[0] == digit_for(first_letter)) {
        if (code_count == 1) return -1;
        start = 1;
    }

    std::uint8_t encoded[max_output_bytes];
    auto initial = values[1];
    if (initial >= 'a' && initial <= 'z') initial -= 'a' - 'A';
    encoded[0] = static_cast<std::uint8_t>(initial);
    for (std::size_t index = 0; index < 3; ++index) {
        const auto digit = start + index < code_count ? mapped[start + index] : 0;
        encoded[index + 1] = static_cast<std::uint8_t>('0' + digit);
    }

    if (output == nullptr || output_capacity < max_output_bytes) return -2;
    for (std::size_t index = 0; index < max_output_bytes; ++index) output[index] = encoded[index];
    return static_cast<std::int64_t>(max_output_bytes);
}
