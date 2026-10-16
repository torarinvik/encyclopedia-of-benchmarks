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

extern "C" std::int64_t problem187(std::int64_t max_number) noexcept {
    if (max_number < 0 || max_number > 100'000'000) return -1;
    const std::int64_t prime_limit = max_number / 2;
    if (prime_limit <= 2) return 0;

    std::vector<std::uint64_t> composite((static_cast<std::uint64_t>(prime_limit) + 63) / 64);
    mark_composite(composite, 0);
    mark_composite(composite, 1);
    for (std::int64_t prime = 2; prime <= (prime_limit - 1) / prime; ++prime) {
        if (is_composite(composite, prime)) continue;
        for (std::int64_t multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    std::int64_t right_value = prime_limit - 1;
    while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
    if (right_value < 2) return 0;
    std::int64_t prime_count = 0;
    for (std::int64_t value = 2; value <= right_value; ++value)
        if (!is_composite(composite, value)) ++prime_count;

    std::int64_t right_rank = prime_count - 1, left_rank = 0, count = 0;
    for (std::int64_t left_value = 2; left_value <= right_value; ++left_value) {
        if (is_composite(composite, left_value)) continue;
        if (left_value > right_value) break;
        while (right_rank >= left_rank && left_value * right_value >= max_number) {
            --right_rank;
            --right_value;
            while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
        }
        if (right_rank < left_rank) break;
        count += right_rank - left_rank + 1;
        ++left_rank;
    }
    return count;
}
