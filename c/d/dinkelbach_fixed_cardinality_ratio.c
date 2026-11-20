#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 12u
#define MAX_INPUT_LENGTH 27u
#define RATIO_BASE INT64_C(120001)

static int64_t gcd_positive(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t choose_small(size_t n, size_t k)
{
    if (k > n - k) k = n - k;
    int64_t result = 1;
    for (size_t index = 1; index <= k; ++index)
        result = result * (int64_t)(n - k + index) / (int64_t)index;
    return result;
}

static int score_precedes(size_t candidate, size_t current, const int64_t scores[MAX_ITEMS])
{
    if (scores[candidate] != scores[current]) return scores[candidate] > scores[current];
    return candidate < current;
}

int64_t dinkelbach_fixed_cardinality_ratio(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t k_value = input[1];
    if (n_value < 1 || n_value > (int64_t)MAX_ITEMS || k_value < 1 || k_value > n_value ||
        length != 2u + 2u * (size_t)n_value) return -1;

    const size_t n = (size_t)n_value;
    const size_t k = (size_t)k_value;
    int64_t numerators[MAX_ITEMS];
    int64_t denominators[MAX_ITEMS];
    for (size_t item = 0; item < n; ++item) {
        const int64_t numerator = input[2u + 2u * item];
        const int64_t denominator = input[3u + 2u * item];
        if (numerator < 0 || numerator > 10000 || denominator < 1 || denominator > 10000)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
    }

    int64_t ratio_numerator = 0;
    int64_t ratio_denominator = 1;
    const int64_t iteration_limit = choose_small(n, k) + 1;
    for (int64_t iteration = 0; iteration < iteration_limit; ++iteration) {
        int64_t scores[MAX_ITEMS] = {0};
        size_t order[MAX_ITEMS];
        for (size_t item = 0; item < n; ++item) {
            scores[item] = numerators[item] * ratio_denominator -
                           ratio_numerator * denominators[item];
            order[item] = item;
        }
        for (size_t item = 1; item < n; ++item) {
            const size_t current = order[item];
            size_t position = item;
            while (position > 0 && score_precedes(current, order[position - 1u], scores)) {
                order[position] = order[position - 1u];
                --position;
            }
            order[position] = current;
        }

        int64_t selected_numerator = 0;
        int64_t selected_denominator = 0;
        for (size_t rank = 0; rank < k; ++rank) {
            const size_t item = order[rank];
            selected_numerator += numerators[item];
            selected_denominator += denominators[item];
        }
        const int64_t residual = selected_numerator * ratio_denominator -
                                 ratio_numerator * selected_denominator;
        if (residual < 0) return -1;
        if (residual == 0) {
            const int64_t divisor = gcd_positive(selected_numerator, selected_denominator);
            return (selected_numerator / divisor) * RATIO_BASE + selected_denominator / divisor;
        }

        const int64_t divisor = gcd_positive(selected_numerator, selected_denominator);
        ratio_numerator = selected_numerator / divisor;
        ratio_denominator = selected_denominator / divisor;
    }
    return -1;
}
