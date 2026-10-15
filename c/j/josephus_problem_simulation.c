#include <stddef.h>
#include <stdint.h>
int64_t josephus_problem_simulation(const int64_t *values, size_t length) {
    if (length != 2) return -1;
    const int64_t n_value = values[0], step = values[1];
    if (n_value < 1 || n_value > 512 || step < 1) return -1;
    int64_t people[512];
    size_t remaining = (size_t)n_value;
    for (size_t i = 0; i < remaining; ++i) people[i] = (int64_t)i + 1;
    size_t current = 0;
    while (remaining > 1) {
        const size_t offset = (size_t)((step - 1) % (int64_t)remaining);
        const size_t removed = (current + offset) % remaining;
        for (size_t i = removed; i + 1 < remaining; ++i) people[i] = people[i + 1];
        --remaining;
        current = removed % remaining;
    }
    return people[0];
}
