#include <stddef.h>
#include <stdint.h>

#define MAX_MODULUS 64
#define MAX_INPUT_LENGTH 2

int64_t pisano_period(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_MODULUS) return -1;

    const int64_t modulus = input[0];
    const int64_t initial_next = 1 % modulus;
    int64_t previous = 0;
    int64_t current = initial_next;
    for (int64_t period = 1; period <= 6 * modulus; ++period) {
        const int64_t next = (previous + current) % modulus;
        previous = current;
        current = next;
        if (previous == 0 && current == initial_next) return period;
    }
    return -1;
}
