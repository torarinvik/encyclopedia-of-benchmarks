#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_n = 64, max_q = 15, max_parseable = 32;

std::int64_t at_prefix(const std::array<std::int64_t, max_q>& q,
        const std::array<std::int64_t, max_q>& prefix, std::size_t count,
        std::int64_t value) {
    if (value == 0) return 0;
    for (std::size_t i = 0; i < count; ++i)
        if (q[i] == value) return prefix[i];
    return 0;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}  // namespace

extern "C" std::int64_t dirichlet_convolution_and_prefix_sums(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = input[0];
    std::array<std::int64_t, max_q> q{};
    std::size_t count = 0;
    for (std::int64_t left = 1; left <= n;) {
        const auto value = n / left;
        q[count++] = value;
        left = n / value + 1;
    }
    for (std::size_t i = 0; i < count / 2; ++i)
        std::swap(q[i], q[count - 1 - i]);
    if (length != 1 + 2 * count) return -1;

    std::array<std::int64_t, max_q> f{}, g{}, result{};
    for (std::size_t i = 0; i < count; ++i) {
        f[i] = input[1 + i];
        g[i] = input[1 + count + i];
        if (f[i] < 1 || f[i] >= modulus || g[i] < 1 || g[i] >= modulus) return -1;
    }
    const auto needed = 8 * count;
    if (output == nullptr || output_capacity < needed) return -2;

    for (std::size_t out = 0; out < count; ++out) {
        const auto x = q[out];
        std::int64_t total = 0;
        for (std::int64_t left = 1; left <= x;) {
            const auto quotient = x / left;
            const auto right = x / quotient;
            const auto below = x / (quotient + 1);
            auto interval = (at_prefix(q, f, count, right)
                    - at_prefix(q, f, count, below)) % modulus;
            if (interval < 0) interval += modulus;
            std::size_t q_index = 0;
            while (q_index < count && q[q_index] != quotient) ++q_index;
            if (q_index == count) return -1;
            total = (total + interval * g[q_index]) % modulus;
            left = right + 1;
        }
        result[out] = total;
    }
    for (std::size_t i = 0; i < count; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(needed);
}
