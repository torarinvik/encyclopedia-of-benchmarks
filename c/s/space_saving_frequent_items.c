#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t item, estimate, error; } entry;

int64_t space_saving_frequent_items(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 67) return -1;
    int64_t k_raw = input[0], n_raw = input[1];
    if (k_raw < 1 || k_raw > 8 || n_raw < 0 || n_raw > 64 || length != 2+(size_t)n_raw) return -1;
    size_t k = (size_t)k_raw, n = (size_t)n_raw;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < -1000 || input[2+i] > 1000) return -1;
    entry entries[8];
    size_t used = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t item = input[2+i];
        size_t slot = 0;
        while (slot < used && entries[slot].item != item) ++slot;
        if (slot < used) { ++entries[slot].estimate; continue; }
        if (used < k) { entries[used++] = (entry){item,1,0}; continue; }
        size_t victim = 0;
        for (size_t j = 1; j < used; ++j)
            if (entries[j].estimate < entries[victim].estimate ||
                (entries[j].estimate == entries[victim].estimate && entries[j].item < entries[victim].item)) victim = j;
        int64_t minimum = entries[victim].estimate;
        entries[victim] = (entry){item,minimum+1,minimum};
    }
    for (size_t i = 1; i < used; ++i) {
        entry value = entries[i];
        size_t j = i;
        while (j > 0 && entries[j-1].item > value.item) { entries[j] = entries[j-1]; --j; }
        entries[j] = value;
    }
    size_t words = 1+3*used, bytes = 8*words;
    if (output == NULL || capacity < bytes) return -2;
    int64_t fields[25]; fields[0] = (int64_t)used;
    for (size_t i = 0; i < used; ++i) {
        fields[1+3*i] = entries[i].item;
        fields[2+3*i] = entries[i].estimate;
        fields[3+3*i] = entries[i].error;
    }
    uint8_t staged[200];
    for (size_t i = 0; i < words; ++i) {
        uint64_t bits = (uint64_t)fields[i];
        for (size_t b = 0; b < 8; ++b) staged[8*i+b] = (uint8_t)(bits >> (8*b));
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
