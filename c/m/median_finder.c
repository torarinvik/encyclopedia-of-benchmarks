/* Prefix medians using the source's lower max-heap and upper min-heap. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_COUNT 64
#define HEAP_CAPACITY 32
#define VALUE_LIMIT 1000000

static void heap_push(int64_t heap[HEAP_CAPACITY], size_t *size, int is_max, int64_t value)
{
    size_t index = (*size)++;
    heap[index] = value;
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        const int ordered = is_max ? heap[parent] >= heap[index] : heap[parent] <= heap[index];
        if (ordered) break;
        const int64_t temporary = heap[parent];
        heap[parent] = heap[index];
        heap[index] = temporary;
        index = parent;
    }
}

static int64_t heap_pop(int64_t heap[HEAP_CAPACITY], size_t *size, int is_max)
{
    const int64_t result = heap[0];
    heap[0] = heap[--(*size)];
    size_t index = 0;
    for (;;) {
        const size_t left = 2 * index + 1, right = left + 1;
        size_t best = index;
        if (left < *size && (is_max ? heap[left] > heap[best] : heap[left] < heap[best])) best = left;
        if (right < *size && (is_max ? heap[right] > heap[best] : heap[right] < heap[best])) best = right;
        if (best == index) break;
        const int64_t temporary = heap[index];
        heap[index] = heap[best];
        heap[best] = temporary;
        index = best;
    }
    return result;
}

static void write_f64_le(uint8_t *output, size_t position, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t median_finder(const int64_t *input, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_COUNT + 1) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_COUNT || length != (size_t)count_value + 1) return -1;
    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index)
        if (input[index + 1] < -VALUE_LIMIT || input[index + 1] > VALUE_LIMIT) return -1;
    const size_t required = count * 8;
    if (output == NULL || output_capacity < required) return -2;

    int64_t lower[HEAP_CAPACITY], upper[HEAP_CAPACITY];
    size_t lower_size = 0, upper_size = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (lower_size == HEAP_CAPACITY && lower_size > upper_size && value <= lower[0]) {
            /* Make room before the source's lower-heap insert-then-rebalance step. */
            heap_push(upper, &upper_size, 0, heap_pop(lower, &lower_size, 1));
            heap_push(lower, &lower_size, 1, value);
        } else {
            if (lower_size == 0 || value <= lower[0]) heap_push(lower, &lower_size, 1, value);
            else heap_push(upper, &upper_size, 0, value);
            if (lower_size > upper_size + 1)
                heap_push(upper, &upper_size, 0, heap_pop(lower, &lower_size, 1));
            else if (upper_size > lower_size)
                heap_push(lower, &lower_size, 1, heap_pop(upper, &upper_size, 0));
        }

        const double median = lower_size == upper_size
            ? ((double)lower[0] + (double)upper[0]) / 2.0
            : (double)lower[0];
        write_f64_le(output, index * 8, median);
    }
    return (int64_t)required;
}
