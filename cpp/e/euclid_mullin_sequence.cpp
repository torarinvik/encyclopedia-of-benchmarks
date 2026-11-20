#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxParseableLength = 2;
constexpr std::int64_t kMaxN = 8;

std::int64_t least_prime_factor(std::int64_t value) noexcept {
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return divisor;
    }
    return value;
}

std::int64_t euclid_mullin_term(std::int64_t index) noexcept {
    std::int64_t product = 1;
    std::int64_t term = 1;
    for (std::int64_t position = 0; position < index; ++position) {
        term = least_prime_factor(product + 1);
        product *= term;
    }
    return term;
}
}

extern "C" std::int64_t euclid_mullin_sequence(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > kMaxParseableLength) return -1;
    if (length != 1 || input[0] < 1 || input[0] > kMaxN) return -1;
    return euclid_mullin_term(input[0]);
}
