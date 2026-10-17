/* Men-proposing deferred acceptance for bounded complete preference lists. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_LENGTH 129

int64_t stable_matching(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const size_t side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    int64_t men_preferences[MAX_N * MAX_N] = {0};
    int64_t women_rank[MAX_N * MAX_N] = {0};
    for (size_t row = 0; row < 2 * n; ++row) {
        uint8_t seen[MAX_N] = {0};
        const size_t row_start = row < n
            ? 1 + row * n
            : 1 + side_size + (row - n) * n;
        for (size_t rank = 0; rank < n; ++rank) {
            const int64_t participant = input[row_start + rank];
            if (participant < 0 || participant >= (int64_t)n || seen[participant]) return -1;
            seen[participant] = 1;
            if (row < n) men_preferences[row * n + rank] = participant;
            else women_rank[(row - n) * n + (size_t)participant] = (int64_t)rank;
        }
    }

    const size_t output_bytes = 16 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t woman_partner[MAX_N];
    int64_t man_partner[MAX_N];
    size_t next_proposal[MAX_N] = {0};
    size_t free_queue[MAX_N];
    for (size_t index = 0; index < n; ++index) {
        woman_partner[index] = -1;
        man_partner[index] = -1;
        free_queue[index] = index;
    }
    size_t head = 0, tail = 0, queue_count = n;
    while (queue_count > 0) {
        const size_t man = free_queue[head];
        head = (head + 1) % n;
        --queue_count;
        const size_t rank = next_proposal[man]++;
        const size_t woman = (size_t)men_preferences[man * n + rank];
        const int64_t incumbent = woman_partner[woman];
        if (incumbent < 0) {
            woman_partner[woman] = (int64_t)man;
            man_partner[man] = (int64_t)woman;
        } else if (women_rank[woman * n + man] < women_rank[woman * n + (size_t)incumbent]) {
            woman_partner[woman] = (int64_t)man;
            man_partner[man] = (int64_t)woman;
            man_partner[incumbent] = -1;
            free_queue[tail] = (size_t)incumbent;
            tail = (tail + 1) % n;
            ++queue_count;
        } else {
            free_queue[tail] = man;
            tail = (tail + 1) % n;
            ++queue_count;
        }
    }

    for (size_t man = 0; man < n; ++man) {
        const int64_t pair[2] = {(int64_t)man, man_partner[man]};
        for (size_t item = 0; item < 2; ++item) {
            uint64_t bits = (uint64_t)pair[item];
            for (size_t byte = 0; byte < 8; ++byte) {
                output[(man * 2 + item) * 8 + byte] = (uint8_t)(bits & 255);
                bits >>= 8;
            }
        }
    }
    return (int64_t)output_bytes;
}
