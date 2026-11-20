#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_value = 64;
constexpr std::size_t max_small = 8;
constexpr std::size_t max_queries = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_queries;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t batch_gcd_small_range_precomputed(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length + 1) return -1;
    const auto limit_value = input[0], query_value = input[1];
    if (limit_value < 1 || limit_value > static_cast<std::int64_t>(max_value) ||
        query_value < 0 || query_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto limit = static_cast<std::size_t>(limit_value);
    const auto queries = static_cast<std::size_t>(query_value);
    if (length != 2 + 2 * queries) return -1;
    for (std::size_t query = 0; query < queries; ++query) {
        const auto left = input[2 + 2 * query], right = input[3 + 2 * query];
        if (left < 0 || left > limit_value || right < 0 || right > limit_value) return -1;
    }
    const auto required = 8 * queries;
    if (output == nullptr || capacity < required) return -2;

    std::size_t least[max_value + 1]{};
    std::size_t primes[max_value + 1]{};
    std::size_t prime_count = 0;
    for (std::size_t value = 2; value <= limit; ++value) {
        if (least[value] == 0) {
            least[value] = value;
            primes[prime_count++] = value;
        }
        for (std::size_t index = 0; index < prime_count; ++index) {
            const auto prime = primes[index];
            const auto composite = value * prime;
            if (composite > limit || prime > least[value]) break;
            least[composite] = prime;
        }
    }

    std::size_t factors[max_value + 1][3]{};
    factors[1][0] = factors[1][1] = factors[1][2] = 1;
    for (std::size_t value = 2; value <= limit; ++value) {
        const auto prime = least[value];
        const auto quotient = value / prime;
        auto a = factors[quotient][0] * prime;
        auto b = factors[quotient][1], c = factors[quotient][2];
        if (a > b) { const auto t = a; a = b; b = t; }
        if (b > c) { const auto t = b; b = c; c = t; }
        if (a > b) { const auto t = a; a = b; b = t; }
        factors[value][0] = a; factors[value][1] = b; factors[value][2] = c;
    }

    std::size_t small_limit = 1;
    while ((small_limit + 1) * (small_limit + 1) <= limit) ++small_limit;
    std::size_t gcd_table[max_small + 1][max_small + 1]{};
    for (std::size_t left = 1; left <= small_limit; ++left) {
        gcd_table[left][0] = left;
        for (std::size_t right = 1; right < left; ++right)
            gcd_table[left][right] = gcd_table[right][left % right];
    }

    for (std::size_t query = 0; query < queries; ++query) {
        const auto left = static_cast<std::size_t>(input[2 + 2 * query]);
        auto remaining = static_cast<std::size_t>(input[3 + 2 * query]);
        std::size_t result = 0;
        if (left == 0) result = remaining;
        else {
            result = 1;
            for (std::size_t part = 0; part < 3; ++part) {
                const auto factor = factors[left][part];
                const auto common = factor <= small_limit
                    ? gcd_table[factor][remaining % factor]
                    : (remaining % factor == 0 ? factor : 1);
                remaining /= common;
                result *= common;
            }
        }
        store_i64_le(output, 8 * query, static_cast<std::int64_t>(result));
    }
    return static_cast<std::int64_t>(required);
}
