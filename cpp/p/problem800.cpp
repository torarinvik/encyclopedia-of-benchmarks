#include <cmath>
#include <cstdint>
#include <vector>

namespace {
bool is_composite(const std::vector<std::uint64_t>& bits, std::int64_t value) {
    return ((bits[static_cast<std::size_t>(value) >> 6] >> (static_cast<std::uint64_t>(value) & 63U)) & 1U) != 0;
}
void mark_composite(std::vector<std::uint64_t>& bits, std::int64_t value) {
    bits[static_cast<std::size_t>(value) >> 6] |= std::uint64_t{1} << (static_cast<std::uint64_t>(value) & 63U);
}
}

extern "C" std::int64_t problem800(std::int64_t base, std::int64_t degree) noexcept {
    if (base < 2 || base > 1'000'000 || degree < 1 || degree > 1'000'000) return -1;
    const double upper_bound = static_cast<double>(degree) * std::log2(static_cast<double>(base));
    const auto prime_limit = static_cast<std::int64_t>(upper_bound);
    if (prime_limit <= 2) return 0;
    std::vector<std::uint64_t> composite((static_cast<std::uint64_t>(prime_limit) + 63) / 64);
    for (std::int64_t prime = 2; prime <= (prime_limit - 1) / prime; ++prime) {
        if (is_composite(composite, prime)) continue;
        for (std::int64_t multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    std::int64_t right_value = 0, prime_count = 0;
    for (std::int64_t value = 2; value < prime_limit; ++value)
        if (!is_composite(composite, value)) { right_value = value; ++prime_count; }
    if (prime_count < 2) return 0;

    std::int64_t right_rank = prime_count - 1, left_rank = 0, left_value = 2, count = 0;
    while (left_rank < right_rank) {
        while (is_composite(composite, left_value)) ++left_value;
        const double left_log = std::log2(static_cast<double>(left_value));
        while (static_cast<double>(right_value) * left_log
               + static_cast<double>(left_value) * std::log2(static_cast<double>(right_value)) > upper_bound) {
            --right_rank;
            --right_value;
            while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
        }
        count += right_rank - left_rank;
        ++left_rank;
        ++left_value;
    }
    return count;
}
