/* Find the numerator of the closest bounded fraction below a reduced target. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DENOMINATOR 1000000

static int64_t gcd_positive(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t problem71(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    const int64_t target_numerator = input[0];
    const int64_t target_denominator = input[1];
    const int64_t limit = input[2];
    if (target_numerator < 1 || target_denominator <= target_numerator ||
        target_denominator > MAX_DENOMINATOR || limit < 1 || limit > MAX_DENOMINATOR ||
        gcd_positive(target_numerator, target_denominator) != 1) return -1;

    int64_t best_numerator = 0;
    int64_t best_denominator = 1;
    for (int64_t current_denominator = 1; current_denominator <= limit; ++current_denominator) {
        int64_t current_numerator =
            current_denominator * target_numerator / target_denominator;
        if (current_denominator % target_denominator == 0) --current_numerator;
        if (current_numerator * best_denominator > current_denominator * best_numerator) {
            best_numerator = current_numerator;
            best_denominator = current_denominator;
        }
    }
    return best_numerator;
}
