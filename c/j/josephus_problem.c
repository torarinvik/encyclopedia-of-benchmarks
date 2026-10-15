/* Linear-time Josephus recurrence; zero-based internally, one-based result. */
#include <stddef.h>
#include <stdint.h>
int64_t josephus_problem(const int64_t *values, size_t length) {
    if (length != 2) return -1;
    const int64_t n = values[0], step = values[1];
    if (n < 1 || n > 100000 || step < 1) return -1;
    int64_t winner = 0;
    for (int64_t size = 1; size <= n; ++size)
        winner = (winner + step % size) % size;
    return winner + 1;
}
