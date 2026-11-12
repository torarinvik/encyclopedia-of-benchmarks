#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_n = 5;
constexpr std::size_t max_size = 32;
constexpr std::size_t max_input = 33;

std::size_t subset_size(std::size_t mask) {
    std::size_t count = 0;
    while (mask != 0) {
        count += mask & 1U;
        mask >>= 1;
    }
    return count;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t exp_of_set_power_series(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const std::size_t size = std::size_t{1} << n;
    if (length != 1 + size || input[1] != 0) return -1;
    for (std::size_t mask = 0; mask < size; ++mask)
        if (input[1 + mask] < 0 || input[1 + mask] >= modulus) return -1;

    const std::size_t bytes = 8 * size;
    if (output == nullptr || capacity < bytes) return -2;

    std::int64_t inverse[max_n + 1]{};
    std::int64_t result[max_size]{};
    if (n > 0) inverse[1] = 1;
    for (std::size_t k = 2; k <= n; ++k)
        inverse[k] = modulus - (modulus / static_cast<std::int64_t>(k)) *
                     inverse[static_cast<std::size_t>(modulus % static_cast<std::int64_t>(k))] % modulus;
    result[0] = 1;
    for (std::size_t mask = 1; mask < size; ++mask) {
        std::int64_t total = 0;
        for (std::size_t subset = mask; subset != 0; subset = (subset - 1) & mask) {
            auto term = static_cast<std::int64_t>(subset_size(subset)) * input[1 + subset] % modulus;
            term = term * result[mask ^ subset] % modulus;
            total = (total + term) % modulus;
        }
        result[mask] = total * inverse[subset_size(mask)] % modulus;
    }
    for (std::size_t mask = 0; mask < size; ++mask) store_le(output, 8 * mask, result[mask]);
    return static_cast<std::int64_t>(bytes);
}
