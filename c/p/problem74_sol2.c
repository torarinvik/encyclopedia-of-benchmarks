/* Count sol2's bounded, source-ordered digit-factorial chains. */
#include <stdint.h>
#include <stdlib.h>

#define MAX_CHAIN_LENGTH 60
#define MAX_NUMBER_LIMIT 1000000
#define PATH_CAPACITY (MAX_CHAIN_LENGTH + 1)

static const int64_t DIGIT_FACTORIALS[10] = {
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880
};

static int64_t digit_factorial_sum(int64_t value)
{
    int64_t total = 0;
    do {
        total += DIGIT_FACTORIALS[value % 10];
        value /= 10;
    } while (value > 0);
    return total;
}

static int cache_contains(int64_t value, int64_t number_limit, const uint32_t *cache)
{
    return value >= 1 && value < number_limit && cache[value] != 0;
}

static int path_contains(const int64_t *path, size_t path_length, int64_t value)
{
    for (size_t index = 0; index < path_length; ++index)
        if (path[index] == value) return 1;
    return 0;
}

int64_t problem74_sol2(int64_t chain_length, int64_t number_limit)
{
    if (chain_length < 1 || chain_length > MAX_CHAIN_LENGTH ||
        number_limit < 1 || number_limit > MAX_NUMBER_LIMIT) return -1;
    if (number_limit == 1) return 0;

    uint32_t *cache = (uint32_t *)calloc((size_t)number_limit, sizeof(*cache));
    if (cache == NULL) return -1;

    int64_t chains_counter = 0;
    for (int64_t start = 1; start < number_limit; ++start) {
        int64_t path[PATH_CAPACITY];
        size_t path_length = 0;
        int64_t chain_set_length = 0;
        int64_t chain_element = start;
        while (!cache_contains(chain_element, number_limit, cache) &&
               !path_contains(path, path_length, chain_element) &&
               chain_set_length <= chain_length) {
            path[path_length++] = chain_element;
            ++chain_set_length;
            chain_element = digit_factorial_sum(chain_element);
        }
        if (cache_contains(chain_element, number_limit, cache))
            chain_set_length += cache[chain_element];

        cache[start] = (uint32_t)chain_set_length;
        if (chain_set_length == chain_length) ++chains_counter;
    }

    free(cache);
    return chains_counter;
}
