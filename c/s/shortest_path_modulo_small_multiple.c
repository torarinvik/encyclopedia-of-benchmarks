/* Minimum digit sum of a 0/1 multiple, by 0-1 BFS on residues. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(16)
#define DEQUE_CAPACITY ((size_t)512)

static int64_t minimum_digit_sum(int64_t n) {
    int64_t distance[16];
    int64_t deque[512];
    for (size_t i = 0; i < (size_t)n; ++i) distance[i] = INT64_MAX;

    size_t head = 0, tail = 0, count = 0;
    const size_t start = (size_t)(1 % n);
    distance[start] = 1;
    deque[tail] = (int64_t)start;
    tail = (tail + 1) % DEQUE_CAPACITY;
    ++count;

    while (count != 0) {
        const size_t residue = (size_t)deque[head];
        head = (head + 1) % DEQUE_CAPACITY;
        --count;
        const int64_t zero_cost_next = ((int64_t)residue * 10) % n;
        if (distance[(size_t)zero_cost_next] > distance[residue]) {
            distance[(size_t)zero_cost_next] = distance[residue];
            head = (head + DEQUE_CAPACITY - 1) % DEQUE_CAPACITY;
            deque[head] = zero_cost_next;
            ++count;
        }
        const int64_t one_cost_next = (zero_cost_next + 1) % n;
        if (distance[(size_t)one_cost_next] > distance[residue] + 1) {
            distance[(size_t)one_cost_next] = distance[residue] + 1;
            deque[tail] = one_cost_next;
            tail = (tail + 1) % DEQUE_CAPACITY;
            ++count;
        }
    }
    return distance[0];
}

int64_t shortest_path_modulo_small_multiple(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t n = input[0];
    if (n < 1 || n > MAX_N) return -1;
    return minimum_digit_sum(n);
}
