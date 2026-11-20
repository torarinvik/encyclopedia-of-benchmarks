#include <stddef.h>
#include <stdint.h>

static void jsort_sift_down_min(int64_t *values, size_t root, size_t end) {
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] < values[child]) ++child;
        if (values[root] <= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

static void jsort_sift_down_max(int64_t *values, size_t root, size_t end) {
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] > values[child]) ++child;
        if (values[root] >= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

static void jsort_reverse(int64_t *values, size_t length) {
    for (size_t left = 0; left < length / 2; ++left) {
        const size_t right = length - 1 - left;
        const int64_t temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

void jsort(int64_t *values, size_t length) {
    if (values == NULL || length < 2) return;

    for (size_t start = length / 2; start > 0;) {
        --start;
        jsort_sift_down_min(values, start, length);
    }

    jsort_reverse(values, length);
    for (size_t start = length / 2; start > 0;) {
        --start;
        jsort_sift_down_max(values, start, length);
    }
    jsort_reverse(values, length);

    for (size_t index = 1; index < length; ++index) {
        const int64_t key = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}
