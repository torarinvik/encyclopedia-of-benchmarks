/* Historical-simulation Value at Risk. */
#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_RETURNS 64
#define MAX_PARSED_RETURNS 65
#define MAX_SAMPLE INT64_C(1000000000)
#define MAX_INPUT_LENGTH 67
#define INVALID_RESULT (-1.0e300)

static void sift_down(double *values, size_t root_start, size_t end)
{
    size_t root = root_start;
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        double temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

static void heap_sort(double *values, size_t length)
{
    for (size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        double temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

double value_at_risk(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int64_t confidence_micro = input[0], count_value = input[1];
    if (confidence_micro < 1 || confidence_micro >= SCALE || count_value < 1 || count_value > MAX_PARSED_RETURNS)
        return INVALID_RESULT;
    if (length != 2 + (size_t)count_value || count_value > MAX_RETURNS) return INVALID_RESULT;
    size_t count = (size_t)count_value;
    double returns[MAX_RETURNS];
    for (size_t i = 0; i < count; ++i) {
        int64_t value = input[2 + i];
        if (value < -MAX_SAMPLE || value > MAX_SAMPLE) return INVALID_RESULT;
        returns[i] = (double)value / (double)SCALE;
    }
    heap_sort(returns, count);
    double confidence = (double)confidence_micro / (double)SCALE;
    double quantile = 1.0 - confidence;
    double position = (double)(count - 1) * quantile;
    size_t lower = (size_t)position;
    double fraction = position - (double)lower;
    double threshold = lower == count - 1 ? returns[count - 1]
        : returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction;
    return -threshold;
}
