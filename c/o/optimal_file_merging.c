#include <stddef.h>
#include <stdint.h>

#define MAX_FILES 32
#define MAX_SIZE INT64_C(1000000)

int64_t optimal_file_merging(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_FILES + 1) return -1;
    const int64_t count = values[0];
    if (count < 0 || count > MAX_FILES || length != (size_t)count + 1) return -1;
    int64_t files[MAX_FILES];
    for (size_t i = 0; i < (size_t)count; ++i) {
        if (values[i + 1] < 0 || values[i + 1] > MAX_SIZE) return -1;
        files[i] = values[i + 1];
    }
    size_t n = (size_t)count;
    int64_t total = 0;
    while (n > 1) {
        size_t a = 0, b = 1;
        if (files[b] < files[a]) { size_t t = a; a = b; b = t; }
        for (size_t i = 2; i < n; ++i) {
            if (files[i] < files[a]) { b = a; a = i; }
            else if (files[i] < files[b]) b = i;
        }
        const int64_t merged = files[a] + files[b];
        total += merged;
        if (a > b) { size_t t = a; a = b; b = t; }
        files[a] = merged;
        files[b] = files[n - 1];
        --n;
    }
    return total;
}
