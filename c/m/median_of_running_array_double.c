#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH 66

static int less_double(double left, double right) {
    return left < right || (left == 0.0 && right == 0.0 && signbit(left) && !signbit(right));
}
static void push_max(double *heap, size_t *count, double value) {
    size_t position = (*count)++;
    while (position > 0 && less_double(heap[(position - 1) / 2], value)) {
        const size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
static double pop_max(double *heap, size_t *count) {
    const double result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) {
        size_t child = 2 * position + 1;
        if (child + 1 < *count && less_double(heap[child], heap[child + 1])) ++child;
        if (!less_double(value, heap[child])) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
static void push_min(double *heap, size_t *count, double value) {
    size_t position = (*count)++;
    while (position > 0 && less_double(value, heap[(position - 1) / 2])) {
        const size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
static double pop_min(double *heap, size_t *count) {
    const double result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) {
        size_t child = 2 * position + 1;
        if (child + 1 < *count && less_double(heap[child + 1], heap[child])) ++child;
        if (!less_double(heap[child], value)) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}

int64_t median_of_running_array_double(const double *input, size_t length,
                                      double *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const double count_value = input[0];
    if (!isfinite(count_value) || count_value < 1.0 || count_value > MAX_COUNT || trunc(count_value) != count_value ||
        length != 1 + (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    double lower[MAX_COUNT], upper[MAX_COUNT], medians[MAX_COUNT];
    size_t lower_count = 0, upper_count = 0;
    for (size_t i = 0; i < count; ++i) {
        const double sample = input[i + 1];
        if (!isfinite(sample) || sample < -1000000.0 || sample > 1000000.0) return -1;
        if (upper_count > 0 && less_double(sample, upper[0])) push_max(lower, &lower_count, sample);
        else push_min(upper, &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, &upper_count, pop_max(lower, &lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, &lower_count, pop_min(upper, &upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2.0;
    }
    if (output == NULL || capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = medians[i];
    return (int64_t)count;
}
