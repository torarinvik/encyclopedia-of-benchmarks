#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_EVENTS (2 * MAX_N)

static void sift_down(int64_t *events, size_t root, size_t count) {
    while (root < count / 2) {
        size_t child = 2 * root + 1;
        if (child + 1 < count && events[child] < events[child + 1]) ++child;
        if (events[root] >= events[child]) break;
        const int64_t temporary = events[root];
        events[root] = events[child];
        events[child] = temporary;
        root = child;
    }
}

static void heap_sort(int64_t *events, size_t count) {
    size_t start = count / 2;
    while (start > 0) { --start; sift_down(events, start, count); }
    size_t end = count;
    while (end > 1) {
        --end;
        const int64_t temporary = events[0];
        events[0] = events[end];
        events[end] = temporary;
        sift_down(events, 0, end);
    }
}

int64_t segment_union_length_klee(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 130) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 2 * n) return -1;
    int64_t events[MAX_EVENTS];
    for (size_t i = 0; i < n; ++i) {
        const int64_t left = input[1 + 2 * i], right = input[2 + 2 * i];
        if (left < -1000 || left > right || right > 1000) return -1;
        events[2 * i] = 2 * (left + 1000);
        events[2 * i + 1] = 2 * (right + 1000) + 1;
    }
    const size_t event_count = 2 * n;
    if (event_count == 0) return 0;
    heap_sort(events, event_count);
    int64_t active = 0, total = 0, previous = 0;
    size_t index = 0;
    while (index < event_count) {
        const int64_t coordinate_code = events[index] / 2;
        const int64_t coordinate = coordinate_code - 1000;
        if (index > 0 && active > 0) total += coordinate - previous;
        int64_t delta = 0;
        while (index < event_count && events[index] / 2 == coordinate_code) {
            delta += (events[index] % 2 == 0) ? 1 : -1;
            ++index;
        }
        active += delta;
        previous = coordinate;
    }
    return total;
}
