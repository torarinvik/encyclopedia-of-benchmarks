#include <stddef.h>
#include <stdint.h>

#define MAX_VALIDATORS INT64_C(128)
#define MAX_STAKE INT64_C(1000000)
#define MAX_TOTAL_STAKE INT64_C(128000000)
#define MAX_INPUT_VALUES ((size_t)131)

int64_t roulette_wheel_selection(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;

    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_VALIDATORS) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return -1;

    int64_t total = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t stake = input[1 + index];
        if (stake < 1 || stake > MAX_STAKE) return -1;
        if (total > MAX_TOTAL_STAKE - stake) return -1;
        total += stake;
    }

    const int64_t ticket = input[1 + count];
    if (ticket < 0 || ticket >= total) return -1;

    int64_t cumulative = 0;
    for (size_t index = 0; index < count; ++index) {
        cumulative += input[1 + index];
        if (ticket < cumulative) return (int64_t)index + 1;
    }
    return -1;
}
