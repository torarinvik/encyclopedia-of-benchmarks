/* Two-stack sliding window with aggregate GCD, preserving the earliest shortest window. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 128

static int64_t gcd_positive(int64_t a, int64_t b)
{
    while (b != 0) { const int64_t remainder = a % b; a = b; b = remainder; }
    return a;
}

static void push(int64_t value, int64_t *items, int64_t *aggregates, size_t *length)
{
    items[*length] = value;
    aggregates[*length] = *length == 0 ? value : gcd_positive(aggregates[*length - 1], value);
    ++*length;
}

int64_t shortest_coprime_segment(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (input[i] < 1 || input[i] > 1000) return -1;

    int64_t front[MAX_LENGTH], front_gcd[MAX_LENGTH], back[MAX_LENGTH], back_gcd[MAX_LENGTH];
    size_t front_length = 0, back_length = 0;
    size_t left = 0, best_start = 0, best_length = length + 1;
    for (size_t right = 0; right < length; ++right) {
        push(input[right], back, back_gcd, &back_length);
        int64_t window_gcd = gcd_positive(front_length ? front_gcd[front_length - 1] : 0,
                                          back_length ? back_gcd[back_length - 1] : 0);
        while (window_gcd == 1) {
            const size_t current_length = right - left + 1;
            if (current_length < best_length) { best_length = current_length; best_start = left; }
            if (front_length == 0) {
                while (back_length > 0) {
                    const int64_t value = back[--back_length];
                    push(value, front, front_gcd, &front_length);
                }
            }
            --front_length;
            ++left;
            window_gcd = gcd_positive(front_length ? front_gcd[front_length - 1] : 0,
                                      back_length ? back_gcd[back_length - 1] : 0);
        }
    }
    if (best_length > length) return 0;
    const size_t byte_count = best_length * sizeof(int64_t);
    if (output == NULL || output_capacity < byte_count) return -2;
    for (size_t i = 0; i < best_length; ++i) {
        const uint64_t bits = (uint64_t)input[best_start + i];
        for (size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)byte_count;
}
