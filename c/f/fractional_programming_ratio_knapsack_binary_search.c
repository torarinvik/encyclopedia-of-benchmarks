#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 12, MAX_WEIGHT = 32, MAX_PARSEABLE_INPUT = 27 };
static const int64_t SCALE = INT64_C(1000000);
static const int64_t MAX_SCALED_RATIO = INT64_C(1000000000);
static const int64_t NEGATIVE_INFINITY = INT64_MIN / 4;

static int ratio_feasible(const int64_t numerators[MAX_ITEMS],
                          const int64_t denominators[MAX_ITEMS],
                          size_t n, size_t required_weight, int64_t threshold)
{
    int64_t current[MAX_WEIGHT + 1];
    int64_t next[MAX_WEIGHT + 1];
    for (size_t weight = 0; weight <= required_weight; ++weight)
        current[weight] = NEGATIVE_INFINITY;
    current[0] = 0;

    for (size_t item = 0; item < n; ++item) {
        for (size_t weight = 0; weight <= required_weight; ++weight)
            next[weight] = current[weight];
        const int64_t score = SCALE * numerators[item] - threshold * denominators[item];
        for (size_t weight = 0; weight <= required_weight; ++weight) {
            if (current[weight] == NEGATIVE_INFINITY) continue;
            const size_t sum = weight + (size_t)denominators[item];
            const size_t target = sum < required_weight ? sum : required_weight;
            const int64_t candidate = current[weight] + score;
            if (candidate > next[target]) next[target] = candidate;
        }
        for (size_t weight = 0; weight <= required_weight; ++weight)
            current[weight] = next[weight];
    }
    return current[required_weight] >= 0;
}

int64_t fractional_programming_ratio_knapsack_binary_search(const int64_t *input,
                                                             size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t required_value = input[1];
    if (n_value < 1 || n_value > MAX_ITEMS || required_value < 1 ||
        required_value > MAX_WEIGHT || length != 2u + 2u * (size_t)n_value)
        return -1;

    const size_t n = (size_t)n_value;
    const size_t required_weight = (size_t)required_value;
    int64_t numerators[MAX_ITEMS] = {0};
    int64_t denominators[MAX_ITEMS] = {0};
    int64_t denominator_sum = 0;
    for (size_t item = 0; item < n; ++item) {
        const int64_t numerator = input[2u + 2u * item];
        const int64_t denominator = input[3u + 2u * item];
        if (numerator < 0 || numerator > 1000 || denominator < 1 || denominator > 8)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
        denominator_sum += denominator;
    }
    if (required_weight > (size_t)denominator_sum) return -1;

    int64_t low = 0;
    int64_t high = MAX_SCALED_RATIO + 1;
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (ratio_feasible(numerators, denominators, n, required_weight, middle))
            low = middle;
        else
            high = middle;
    }
    return low;
}
