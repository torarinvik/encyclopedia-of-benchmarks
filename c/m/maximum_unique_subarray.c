#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t maximum_unique_subarray(const int64_t *values, size_t length) {
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    int64_t keys[512] = {0};
    size_t last_seen[512] = {0};
    bool occupied[512] = {false};
    size_t left = 0;
    int64_t window_sum = 0;
    int64_t best = 0;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value < 1 || value > 10000) return -1;
        size_t slot = (size_t)value % 512;
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % 512;
        size_t previous = last_seen[slot];
        while (left < previous) {
            window_sum -= values[left];
            ++left;
        }
        window_sum += value;
        keys[slot] = value;
        occupied[slot] = true;
        last_seen[slot] = index + 1;
        if (window_sum > best) best = window_sum;
    }
    return best;
}
