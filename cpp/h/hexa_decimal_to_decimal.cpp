#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 64;
constexpr std::size_t max_parseable_input_length = 65;
constexpr std::int64_t invalid_result = -2'147'483'649LL;
constexpr std::uint64_t uint32_modulus = 4'294'967'296ULL;
}

extern "C" std::int64_t hexa_decimal_to_decimal(const std::int64_t *input, std::size_t length) noexcept {
    if (length > max_parseable_input_length) return invalid_result;
    if (length == 0) return 0;
    if (length > max_input_length || input == nullptr) return invalid_result;

    std::uint64_t accumulator = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto code = input[index];
        std::int64_t digit;
        if (code >= 48 && code <= 57) digit = code - 48;
        else if (code >= 65 && code <= 70) digit = code - 55;
        else if (code >= 97 && code <= 102) digit = code - 87;
        else return invalid_result;
        accumulator = (accumulator * 16 + static_cast<std::uint64_t>(digit)) % uint32_modulus;
    }
    if (accumulator <= 2'147'483'647ULL) return static_cast<std::int64_t>(accumulator);
    return static_cast<std::int64_t>(accumulator) - static_cast<std::int64_t>(uint32_modulus);
}
