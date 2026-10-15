/* Generate perfect numbers through Lucas-Lehmer-tested Mersenne exponents. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_input = INT64_C(2305843009213693951);

std::uint64_t get_prime_limit(std::int64_t value) noexcept {
    auto scaled = static_cast<std::uint64_t>(value) * 8u + 1u;
    std::uint64_t limit = 0;
    while (scaled >= 4u) {
        scaled /= 4u;
        ++limit;
    }
    return limit;
}

bool is_prime(std::uint64_t value) noexcept {
    if (value < 2) return false;
    for (std::uint64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

bool is_mersenne_prime(std::uint64_t exponent) noexcept {
    if (exponent == 2) return true;
    if (exponent < 2) return false;
    const auto modulus = (std::uint64_t{1} << exponent) - 1;
    std::uint64_t residue = 4;
    for (std::uint64_t iteration = 0; iteration < exponent - 2; ++iteration)
        residue = (residue * residue - 2) % modulus;
    return residue == 0;
}
}

extern "C" std::int64_t faster_perfect_numbers(std::int64_t value, std::uint8_t *output,
                                                std::size_t output_capacity) noexcept {
    if (value < 0 || value > max_input) return -1;
    std::array<std::int64_t, 8> perfects{};
    std::size_t count = 0;
    const auto limit = get_prime_limit(value);
    for (std::uint64_t exponent = 2; exponent <= limit; ++exponent) {
        if (!is_prime(exponent) || !is_mersenne_prime(exponent)) continue;
        const auto mersenne = (std::uint64_t{1} << exponent) - 1;
        const auto perfect = mersenne * (std::uint64_t{1} << (exponent - 1));
        if (perfect <= static_cast<std::uint64_t>(value))
            perfects[count++] = static_cast<std::int64_t>(perfect);
    }
    const auto required = count * sizeof(std::int64_t);
    if (required > 0 && output == nullptr) return -2;
    if (output_capacity < required) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto bits = static_cast<std::uint64_t>(perfects[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(required);
}
