#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

static void sift_down(int64_t *heap, size_t heap_size, size_t root, int min_heap) {
    for (;;) {
        size_t best = root;
        size_t left = root * 2 + 1;
        size_t right = left + 1;
        if (left < heap_size && (min_heap ? heap[left] < heap[best] : heap[left] > heap[best])) {
            best = left;
        }
        if (right < heap_size && (min_heap ? heap[right] < heap[best] : heap[right] > heap[best])) {
            best = right;
        }
        if (best == root) return;
        int64_t temporary = heap[root];
        heap[root] = heap[best];
        heap[best] = temporary;
        root = best;
    }
}

int64_t kth_element_finder(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 259) return INVALID_RESULT;
    int64_t mode = input[0], n_value = input[1], k_value = input[2];
    if ((mode != 0 && mode != 1) || n_value < 1 || n_value > 256 ||
        k_value < 1 || k_value > n_value || length != (size_t)n_value + 3) {
        return INVALID_RESULT;
    }
    size_t n = (size_t)n_value, k = (size_t)k_value;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 3] < -1000000 || input[i + 3] > 1000000) return INVALID_RESULT;
    }

    int min_heap = mode == 0;
    int64_t heap[256];
    for (size_t i = 0; i < k; ++i) heap[i] = input[i + 3];
    for (size_t i = k / 2; i > 0; --i) sift_down(heap, k, i - 1, min_heap);
    for (size_t i = k; i < n; ++i) {
        int64_t value = input[i + 3];
        if ((min_heap && value > heap[0]) || (!min_heap && value < heap[0])) {
            heap[0] = value;
            sift_down(heap, k, 0, min_heap);
        }
    }
    return heap[0];
}
