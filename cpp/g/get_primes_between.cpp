/* Primes strictly between bounded prime endpoints, encoded as ASCII. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_prime_count = 256;

bool is_prime_candidate(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::size_t decimal_length(std::int64_t value) noexcept {
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

std::size_t write_decimal(std::uint8_t *output, std::size_t offset,
                          std::int64_t value) noexcept {
    if (value >= 100) {
        output[offset++] = static_cast<std::uint8_t>('0' + value / 100);
        value %= 100;
    }
    if (value >= 10) {
        output[offset++] = static_cast<std::uint8_t>('0' + value / 10);
        value %= 10;
    }
    output[offset++] = static_cast<std::uint8_t>('0' + value);
    return offset;
}
} // namespace

extern "C" std::int64_t get_primes_between(const std::int64_t *values,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const auto p1 = values[0];
    const auto p2 = values[1];
    if (p1 < 2 || p1 > 997 || p2 < 2 || p2 > 997 || p1 >= p2 ||
        !is_prime_candidate(p1) || !is_prime_candidate(p2)) return -1;

    std::array<std::int64_t, max_prime_count> primes{};
    std::size_t count = 0;
    for (auto candidate = p1 + 1; candidate < p2; ++candidate) {
        if (is_prime_candidate(candidate)) primes[count++] = candidate;
    }
    if (count == 0) return -1;

    std::size_t required = count - 1;
    for (std::size_t index = 0; index < count; ++index)
        required += decimal_length(primes[index]);
    if (output == nullptr || output_capacity < required) return -2;

    std::size_t written = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (index != 0) output[written++] = ',';
        written = write_decimal(output, written, primes[index]);
    }
    return static_cast<std::int64_t>(written);
}
