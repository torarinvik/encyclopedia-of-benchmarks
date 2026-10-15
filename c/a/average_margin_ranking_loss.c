/* Average pairwise hinge loss for ranked scores. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define INVALID_RESULT (-1.0e300)

double average_margin_ranking_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5 || length > 2 * MAX_LENGTH + 3) return INVALID_RESULT;
    const int64_t count_value = values[0];
    const int64_t margin_value = values[1];
    const int64_t label_value = values[2];
    if (count_value < 1 || count_value > MAX_LENGTH || length != 2 * (size_t)count_value + 3 ||
        margin_value < 0 || margin_value > 1000 || (label_value != 1 && label_value != -1)) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    double total = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t first = values[index + 3];
        const int64_t second = values[index + 3 + count];
        if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return INVALID_RESULT;
        const double loss = (double)margin_value - (double)label_value * ((double)first - (double)second);
        if (loss > 0.0) total += loss;
    }
    return total / (double)count;
}
