#include <stddef.h>
#include <stdint.h>

static void histogram_put(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        output[offset+i] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t exponential_histogram_window(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 130 || input[0] < 1 || input[0] > 64 ||
        input[1] < 0 || input[1] > 128) return -1;
    size_t window = (size_t)input[0], n = (size_t)input[1];
    if (length != 2+n) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    if (!output || capacity < 8*n) return -2;
    size_t ends[128] = {0}, sizes[128] = {0}, used = 0;
    for (size_t time = 0; time < n; ++time) {
        while (used && time >= window && ends[0] <= time-window) {
            for (size_t j = 1; j < used; ++j) { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
            --used;
        }
        if (input[2+time] == 1) { ends[used] = time; sizes[used] = 1; ++used; }
        for (size_t size = 1; size <= 128; size *= 2) {
            size_t first = used, second = used, found = 0;
            for (size_t j = 0; j < used; ++j) if (sizes[j] == size) {
                if (found == 0) first = j;
                else if (found == 1) second = j;
                ++found;
            }
            if (found > 2) {
                sizes[second] = 2*size;
                for (size_t j = first+1; j < used; ++j) { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
                --used;
            }
        }
        size_t total = 0;
        for (size_t j = 0; j < used; ++j) total += sizes[j];
        int64_t estimate = (int64_t)(2*total - (used ? sizes[0] : 0));
        histogram_put(output, 8*time, estimate);
    }
    return (int64_t)(8*n);
}
