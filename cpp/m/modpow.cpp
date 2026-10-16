#include <cstddef>
#include <cstdint>
namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_parseable_input_length = 4;
constexpr std::int64_t max_component = 89000000;
constexpr std::int64_t max_exponent = 64;
}
extern "C" std::int64_t modpow(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable_input_length) return invalid_result;
    if (length != 3) return invalid_result;
    auto base = input[0], exponent = input[1], modulus = input[2];
    if (base < 0 || base > max_component || exponent < 0 || exponent > max_exponent
        || modulus < 1 || modulus > max_component) return invalid_result;
    if (exponent == 0) {
        if (base == 0) return invalid_result;
        return 1 % modulus;
    }
    if (base == 0) return 0;
    std::int64_t result = 1 % modulus;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            result = (result * base) % modulus;
            exponent -= 1;
        } else {
            base = (base * base) % modulus;
            exponent /= 2;
        }
    }
    return result;
}
