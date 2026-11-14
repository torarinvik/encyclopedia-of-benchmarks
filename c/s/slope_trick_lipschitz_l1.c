/* Uncompiled and unexecuted two-heap slope-trick draft. */
#include <stddef.h>
#include <stdint.h>

static void heap_push(int64_t *heap, size_t *count, int64_t value) {
    size_t i = (*count)++;
    while (i > 0) {
        size_t parent = (i-1)/2;
        if (heap[parent] >= value) break;
        heap[i] = heap[parent]; i = parent;
    }
    heap[i] = value;
}
static void heap_replace(int64_t *heap, size_t count, int64_t value) {
    size_t i = 0;
    while (2*i+1 < count) {
        size_t child = 2*i+1;
        if (child+1 < count && heap[child+1] > heap[child]) ++child;
        if (heap[child] <= value) break;
        heap[i] = heap[child]; i = child;
    }
    heap[i] = value;
}
int64_t slope_trick_lipschitz_l1(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > 100) return -1;
    size_t n = (size_t)input[0];
    if (length != n+2) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 100) return -1;
    int64_t left[128], right[128], shift_l = 0, shift_r = 0, answer = 0;
    size_t ln = 0, rn = 0;
    for (size_t i = 0; i < n; ++i) {
        shift_l -= input[1]; shift_r += input[1];
        heap_push(left, &ln, input[2+i]-shift_l);
        heap_push(right, &rn, shift_r-input[2+i]);
        int64_t l = left[0]+shift_l, r = shift_r-right[0];
        if (l > r) {
            answer += l-r;
            heap_replace(left, ln, r-shift_l);
            heap_replace(right, rn, shift_r-l);
        }
    }
    return answer;
}
