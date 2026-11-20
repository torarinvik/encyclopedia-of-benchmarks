#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH INT64_C(8)
#define MAX_SYMBOL INT64_C(25)
#define ALPHABET_SIZE 26

static int64_t factorial(int64_t value) {
    int64_t result = 1;
    for (int64_t factor = 2; factor <= value; ++factor) result *= factor;
    return result;
}

int64_t alphabetic_anagrams(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 10) return -1;
    const int64_t n = input[0];
    if (n < 0 || n > MAX_LENGTH || length != (size_t)n + 1) return -1;
    int64_t frequency[ALPHABET_SIZE] = {0};
    for (int64_t position = 0; position < n; ++position) {
        const int64_t symbol = input[position + 1];
        if (symbol < 0 || symbol > MAX_SYMBOL) return -1;
        ++frequency[symbol];
    }

    int64_t denominator = 1;
    for (size_t symbol = 0; symbol < ALPHABET_SIZE; ++symbol)
        denominator *= factorial(frequency[symbol]);
    int64_t ways = factorial(n) / denominator;
    int64_t rank = 1, remaining = n;
    for (int64_t position = 0; position < n; ++position) {
        const int64_t actual = input[position + 1];
        for (int64_t smaller = 0; smaller < actual; ++smaller)
            if (frequency[smaller] > 0)
                rank += ways * frequency[smaller] / remaining;
        ways = ways * frequency[actual] / remaining;
        --frequency[actual];
        --remaining;
    }
    return rank;
}
