/* Count primes through limit with Pritchard's dynamic wheel sieve. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT 1024
#define LINK_COUNT (MAX_LIMIT + 2)

int64_t sieve_of_pritchard(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 2) return -1;
    if (length != 1 || input[0] < 2 || input[0] > MAX_LIMIT) return -1;

    const int32_t limit = (int32_t)input[0];
    const int32_t sentinel = limit + 1;
    int32_t next_node[LINK_COUNT] = {0};
    int32_t previous[LINK_COUNT] = {0};
    next_node[1] = sentinel;
    next_node[sentinel] = sentinel;
    previous[sentinel] = 1;

    int32_t wheel_length = 2;
    int32_t prime = 3;
    int64_t prime_count = 1; /* 2 */
    while (prime * prime <= limit) {
        if (wheel_length < limit) {
            const int32_t target = prime * wheel_length < limit
                                 ? prime * wheel_length : limit;
            int32_t wheel_value = 1;
            int32_t candidate = wheel_length + 1;
            while (candidate <= target) {
                const int32_t tail = previous[sentinel];
                next_node[tail] = candidate;
                previous[candidate] = tail;
                next_node[candidate] = sentinel;
                previous[sentinel] = candidate;
                wheel_value = next_node[wheel_value];
                candidate = wheel_length + wheel_value;
            }
            wheel_length = target;
        }

        int32_t wheel_value = prime;
        while (prime * wheel_value <= wheel_length)
            wheel_value = next_node[wheel_value];
        while (wheel_value > 1) {
            wheel_value = previous[wheel_value];
            const int32_t removed = prime * wheel_value;
            const int32_t left = previous[removed];
            const int32_t right = next_node[removed];
            next_node[left] = right;
            previous[right] = left;
        }
        ++prime_count;
        prime = next_node[1];
    }

    if (wheel_length < limit) {
        int32_t wheel_value = 1;
        int32_t candidate = wheel_length + 1;
        while (candidate <= limit) {
            const int32_t tail = previous[sentinel];
            next_node[tail] = candidate;
            previous[candidate] = tail;
            next_node[candidate] = sentinel;
            previous[sentinel] = candidate;
            wheel_value = next_node[wheel_value];
            candidate = wheel_length + wheel_value;
        }
        wheel_length = limit;
    }

    int64_t remaining = 0;
    int32_t value = next_node[1];
    while (value != sentinel) {
        ++remaining;
        value = next_node[value];
    }
    return prime_count + remaining;
}
