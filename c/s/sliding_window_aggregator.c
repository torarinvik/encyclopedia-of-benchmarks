#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 259u
#define MAX_CAPACITY 64u
#define MAX_COUNT 256u
#define MAX_VALUE INT64_C(1000000)
#define INVALID_RESULT INT64_MIN

int64_t sliding_window_aggregator(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > (int64_t)MAX_CAPACITY ||
        input[1] < 1 || input[1] > (int64_t)MAX_COUNT) return INVALID_RESULT;

    const size_t capacity = (size_t)input[0];
    const size_t count = (size_t)input[1];
    if (length != count + 2u) return INVALID_RESULT;
    for (size_t index = 0; index < count; ++index) {
        if (input[index + 2u] < -MAX_VALUE || input[index + 2u] > MAX_VALUE)
            return INVALID_RESULT;
    }

    int64_t window[MAX_CAPACITY] = {0};
    size_t head = 0;
    size_t size = 0;
    int64_t sum = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2u];
        if (size < capacity) {
            const size_t tail = (head + size) % capacity;
            window[tail] = value;
            sum += value;
            ++size;
        } else {
            sum -= window[head];
            window[head] = value;
            sum += value;
            head = (head + 1u) % capacity;
        }
    }
    return sum;
}
