/* Search the pinned prime replacement filter for its default eight-prime family. */
#include <stdbool.h>
#include <stdint.h>

#define PRIME_LIMIT 1000000
#define PRIME 1
#define FILTERED_PRIME 2
#define FILTERED_CHECKED 3
#define CHECKED_NONPRIME 4
#define CHECKED_OTHER_PRIME 5

static int repeated_extra_digits(int64_t value)
{
    int counts[10] = {0};
    int length = 0;
    while (value > 0) {
        ++counts[value % 10];
        ++length;
        value /= 10;
    }
    int distinct = 0;
    for (int digit = 0; digit < 10; ++digit) distinct += counts[digit] != 0;
    return length - distinct;
}

static int count_digit(int64_t value, int digit)
{
    int count = 0;
    while (value > 0) {
        count += value % 10 == digit;
        value /= 10;
    }
    return count;
}

static int64_t replace_all(int64_t value, int digit, int replacement)
{
    int64_t result = value;
    int64_t place = 1;
    while (value > 0) {
        if (value % 10 == digit) result += (replacement - digit) * place;
        value /= 10;
        place *= 10;
    }
    return result;
}

static void mark_checked(uint8_t *state, int64_t value)
{
    if (state[value] == FILTERED_PRIME) state[value] = FILTERED_CHECKED;
    else if (state[value] == 0) state[value] = CHECKED_NONPRIME;
    else if (state[value] == PRIME) state[value] = CHECKED_OTHER_PRIME;
}

int64_t problem51(int64_t ignored)
{
    if (ignored != 0) return -1;
    uint8_t state[PRIME_LIMIT] = {0};
    for (int value = 2; value < PRIME_LIMIT; ++value) state[value] = PRIME;
    for (int prime = 2; prime * prime < PRIME_LIMIT; ++prime) {
        if (state[prime] != PRIME) continue;
        for (int multiple = prime * prime; multiple < PRIME_LIMIT; multiple += prime)
            state[multiple] = 0;
    }
    for (int value = 2; value < PRIME_LIMIT; ++value) {
        if (state[value] == PRIME && repeated_extra_digits(value) >= 3)
            state[value] = FILTERED_PRIME;
    }

    for (int64_t number = 2; number < PRIME_LIMIT; ++number) {
        if (state[number] != FILTERED_PRIME) continue;
        int64_t place = 1;
        while (number / place >= 10) place *= 10;
        bool seen_digits[10] = {false};
        for (; place > 0; place /= 10) {
            const int digit = (number / place) % 10;
            if (seen_digits[digit] || count_digit(number, digit) < 2) continue;
            seen_digits[digit] = true;
            int family_count = 0;
            int64_t family_minimum = INT64_MAX;
            for (int replacement = 0; replacement <= 9; ++replacement) {
                const int64_t member = replace_all(number, digit, replacement);
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
