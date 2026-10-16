/* Sum the numerator digits of the requested convergent for e. */
#include <cstdint>

namespace { constexpr int MAX_DIGITS = 256; }

extern "C" std::int64_t problem65(std::int64_t max_n) noexcept
{
    if (max_n < 1 || max_n > 100) return -1;
    std::int64_t previous[MAX_DIGITS] = {};
    std::int64_t current[MAX_DIGITS] = {};
    std::int64_t next[MAX_DIGITS] = {};
    previous[0] = 1;
    current[0] = 2;
    std::int64_t previous_length = 1, current_length = 1;
    for (std::int64_t i = 2; i <= max_n; ++i) {
        const std::int64_t coefficient = i % 3 == 0 ? (2 * i) / 3 : 1;
        std::int64_t carry = 0;
        for (std::int64_t position = 0; position < current_length; ++position) {
            const std::int64_t old = position < previous_length ? previous[position] : 0;
            const std::int64_t total = coefficient * current[position] + old + carry;
            next[position] = total % 10;
            carry = total / 10;
        }
        std::int64_t next_length = current_length;
        while (carry != 0) { next[next_length++] = carry % 10; carry /= 10; }
        for (std::int64_t position = 0; position < current_length; ++position) previous[position] = current[position];
        for (std::int64_t position = 0; position < next_length; ++position) current[position] = next[position];
        previous_length = current_length;
        current_length = next_length;
    }
    std::int64_t digit_sum = 0;
    for (std::int64_t position = 0; position < current_length; ++position) digit_sum += current[position];
    return digit_sum;
}
