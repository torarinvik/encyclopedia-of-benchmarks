#include <stddef.h>
#include <stdint.h>

#define WEAK_HEAPSORT_MAX_VALUES 256
#define WEAK_HEAPSORT_MAX_INPUT_LENGTH 258

static size_t weak_heapsort_distinguished_ancestor(
    size_t node, const uint8_t reverse[WEAK_HEAPSORT_MAX_VALUES]) {
    while ((node & 1U) == (size_t)reverse[node / 2]) node /= 2;
    return node / 2;
}

static void weak_heapsort_join(int64_t values[WEAK_HEAPSORT_MAX_VALUES],
                               uint8_t reverse[WEAK_HEAPSORT_MAX_VALUES],
                               size_t ancestor, size_t node) {
    if (values[ancestor] < values[node]) {
        const int64_t temporary = values[ancestor];
        values[ancestor] = values[node];
        values[node] = temporary;
        reverse[node] = (uint8_t)!reverse[node];
    }
}

static void weak_heapsort_sift_down(int64_t values[WEAK_HEAPSORT_MAX_VALUES],
                                    uint8_t reverse[WEAK_HEAPSORT_MAX_VALUES],
                                    size_t active_size) {
    size_t node = 1U - (size_t)reverse[0];
    if (node >= active_size) return;
    while (2 * node + (size_t)reverse[node] < active_size)
        node = 2 * node + (size_t)reverse[node];
    while (node != 0) {
        weak_heapsort_join(values, reverse, 0, node);
        node /= 2;
    }
}

int64_t weak_heapsort(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > WEAK_HEAPSORT_MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > WEAK_HEAPSORT_MAX_VALUES) return -1;
    const size_t count = (size_t)raw_count;
    if (length != count + 1) return -1;

    int64_t values[WEAK_HEAPSORT_MAX_VALUES];
    uint8_t reverse[WEAK_HEAPSORT_MAX_VALUES] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[i + 1];
        if (value < -1000 || value > 1000) return -1;
        values[i] = value;
    }

    for (size_t next = count; next > 1; --next) {
        const size_t node = next - 1;
        const size_t ancestor = weak_heapsort_distinguished_ancestor(node, reverse);
        weak_heapsort_join(values, reverse, ancestor, node);
    }
    for (size_t end = count; end > 1; --end) {
        const int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        weak_heapsort_sift_down(values, reverse, end - 1);
    }

    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i)
        checksum += (int64_t)(i + 1) * (values[i] + 1001);
    return checksum;
}
