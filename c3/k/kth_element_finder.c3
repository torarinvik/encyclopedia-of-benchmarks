module kth_element_finder;

const long INVALID_RESULT = -9223372036854775807L - 1;

fn void sift_down(long* heap, usz heap_size, usz root, bool min_heap) {
    while (true) {
        usz best = root;
        usz left = root * 2 + 1;
        usz right = left + 1;
        if (left < heap_size) {
            if ((min_heap && heap[left] < heap[best]) || (!min_heap && heap[left] > heap[best])) best = left;
        }
        if (right < heap_size) {
            if ((min_heap && heap[right] < heap[best]) || (!min_heap && heap[right] > heap[best])) best = right;
        }
        if (best == root) return;
        long temporary = heap[root];
        heap[root] = heap[best];
        heap[best] = temporary;
        root = best;
    }
}

fn long kth_element_finder(long* input, usz length) @export("kth_element_finder") {
    if (input == null || length < 4 || length > 259) return INVALID_RESULT;
    long mode = input[0], n_value = input[1], k_value = input[2];
    if ((mode != 0 && mode != 1) || n_value < 1 || n_value > 256 ||
        k_value < 1 || k_value > n_value || length != (usz)n_value + 3) {
        return INVALID_RESULT;
    }
    usz n = (usz)n_value, k = (usz)k_value;
    for (usz i = 0; i < n; i++) {
        if (input[i + 3] < -1000000 || input[i + 3] > 1000000) return INVALID_RESULT;
    }

    bool min_heap = mode == 0;
    long heap[256];
    for (usz i = 0; i < k; i++) heap[i] = input[i + 3];
    usz start = k / 2;
    while (start > 0) {
        start--;
        sift_down(heap, k, start, min_heap);
    }
    for (usz i = k; i < n; i++) {
        long value = input[i + 3];
        if ((min_heap && value > heap[0]) || (!min_heap && value < heap[0])) {
            heap[0] = value;
            sift_down(heap, k, 0, min_heap);
        }
    }
    return heap[0];
}
