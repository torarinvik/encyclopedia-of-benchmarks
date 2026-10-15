// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }

extern "C" std::int64_t title_case_conversion(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t output_capacity) noexcept {
    if (length == 0 || length > max_length + 1 || input == nullptr) return -1;
    const std::int64_t declared = input[0];
    if (declared < 0 || declared > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(declared) + 1) return -1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(declared); ++index) {
        const std::int64_t value = input[index + 1];
        const bool letter = (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
        if (!letter && value != ' ') return -1;
        if (value == ' ' && (index == 0 || index + 1 == static_cast<std::size_t>(declared) || input[index] == ' ')) return -1;
    }
    if (output_capacity < static_cast<std::size_t>(declared) + 1) return -2;
    bool at_word_start = true;
    for (std::size_t index = 0; index < static_cast<std::size_t>(declared); ++index) {
        std::int64_t value = input[index + 1];
        if (value == ' ') at_word_start = true;
        else if (at_word_start) {
            if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
            at_word_start = false;
        } else if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        output[index] = static_cast<std::uint8_t>(value);
    }
    output[declared] = 0;
    return declared;
}
