/* Count starts with the source's memoized digit-factorial chain length. */
#include <stdint.h>
#include <stddef.h>

#define MAX_START 1000000
#define MAX_CACHE_VALUE 2540160
#define CACHE_SIZE (MAX_CACHE_VALUE + 1)
#define MAX_PATH_LENGTH 128

static const int64_t DIGIT_FACTORIALS[10] = {
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880
};

static int64_t sum_digit_factorials(int64_t value)
{
    int64_t total = 0;
    do {
        total += DIGIT_FACTORIALS[value % 10];
        value /= 10;
    } while (value > 0);
    return total;
}

static int chain_length(int64_t start, uint8_t *cache)
{
    int64_t path[MAX_PATH_LENGTH];
    size_t path_length = 0;
    int64_t current = start;
    int result = 0;

    for (;;) {
        const uint8_t encoded = cache[current];
        if (encoded != 0) {
            result = (int)encoded - 1;
            break;
        }
        const int64_t next = sum_digit_factorials(current);
        int repeats = 0;
        for (size_t index = 0; index < path_length; ++index)
            if (path[index] == next) { repeats = 1; break; }
        if (repeats) {
            cache[current] = 1;
            result = 0;
            break;
        }
        path[path_length++] = current;
        current = next;
    }

    while (path_length > 0) {
        current = path[--path_length];
        ++result;
        cache[current] = (uint8_t)(result + 1);
    }
    return (int)cache[start] - 1;
}

int64_t problem74(int64_t num_terms, int64_t max_start)
{
    if (max_start > MAX_START) return -1;
    if (max_start <= 1) return 0;
    uint8_t cache[CACHE_SIZE] = {0};
    cache[145] = 1;
    cache[169] = 4;
    cache[36301] = 4;
    cache[1454] = 4;
    cache[871] = 3;
    cache[45361] = 3;
    cache[872] = 3;

    int64_t count = 0;
    for (int64_t start = 1; start < max_start; ++start)
        if (chain_length(start, cache) == num_terms) ++count;
    return count;
}
