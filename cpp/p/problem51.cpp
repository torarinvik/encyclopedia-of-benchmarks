/* Search the pinned prime replacement filter for its default eight-prime family. */
#include <cstdint>
#include <limits>

namespace {
constexpr int PRIME_LIMIT = 1'000'000;
constexpr std::uint8_t PRIME = 1, FILTERED_PRIME = 2, FILTERED_CHECKED = 3;
constexpr std::uint8_t CHECKED_NONPRIME = 4, CHECKED_OTHER_PRIME = 5;

int repeated_extra_digits(std::int64_t value) noexcept
{
    int counts[10] = {};
    int length = 0;
    while (value > 0) { ++counts[value % 10]; ++length; value /= 10; }
    int distinct = 0;
    for (int count : counts) distinct += count != 0;
    return length - distinct;
}

int count_digit(std::int64_t value, int digit) noexcept
{
    int count = 0;
    while (value > 0) { count += value % 10 == digit; value /= 10; }
    return count;
}

std::int64_t replace_all(std::int64_t value, int digit, int replacement) noexcept
{
    auto result = value;
    std::int64_t place = 1;
    while (value > 0) {
        if (value % 10 == digit) result += (replacement - digit) * place;
        value /= 10;
        place *= 10;
    }
    return result;
}

void mark_checked(std::uint8_t* state, std::int64_t value) noexcept
{
    if (state[value] == FILTERED_PRIME) state[value] = FILTERED_CHECKED;
    else if (state[value] == 0) state[value] = CHECKED_NONPRIME;
    else if (state[value] == PRIME) state[value] = CHECKED_OTHER_PRIME;
}
}

extern "C" std::int64_t problem51(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    std::uint8_t state[PRIME_LIMIT] = {};
    for (int value = 2; value < PRIME_LIMIT; ++value) state[value] = PRIME;
    for (int prime = 2; prime * prime < PRIME_LIMIT; ++prime) {
        if (state[prime] != PRIME) continue;
        for (int multiple = prime * prime; multiple < PRIME_LIMIT; multiple += prime) state[multiple] = 0;
    }
    for (int value = 2; value < PRIME_LIMIT; ++value) {
        if (state[value] == PRIME && repeated_extra_digits(value) >= 3) state[value] = FILTERED_PRIME;
    }
    for (std::int64_t number = 2; number < PRIME_LIMIT; ++number) {
        if (state[number] != FILTERED_PRIME) continue;
        std::int64_t place = 1;
        while (number / place >= 10) place *= 10;
        bool seen_digits[10] = {};
        for (; place > 0; place /= 10) {
            const int digit = static_cast<int>((number / place) % 10);
            if (seen_digits[digit] || count_digit(number, digit) < 2) continue;
            seen_digits[digit] = true;
            int family_count = 0;
            std::int64_t family_minimum = std::numeric_limits<std::int64_t>::max();
            for (int replacement = 0; replacement <= 9; ++replacement) {
                const auto member = replace_all(number, digit, replacement);
                mark_checked(state, member);
                if (state[member] == FILTERED_PRIME || state[member] == FILTERED_CHECKED) {
                    ++family_count;
                    if (member < family_minimum) family_minimum = member;
                }
            }
            if (family_count == 8) return family_minimum;
        }
    }
    return -1;
}
