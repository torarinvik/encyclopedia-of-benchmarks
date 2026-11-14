// Uncompiled and unexecuted two-heap slope-trick draft.
module slope_trick_lipschitz_l1;
fn void heap_push(long* heap, usz* count, long value) {
    usz i = *count; *count += 1;
    while (i > 0) {
        usz parent = (i-1)/2;
        if (heap[parent] >= value) break;
        heap[i] = heap[parent]; i = parent;
    }
    heap[i] = value;
}
fn void heap_replace(long* heap, usz count, long value) {
    usz i = 0;
    while (2*i+1 < count) {
        usz child = 2*i+1;
        if (child+1 < count && heap[child+1] > heap[child]) child++;
        if (heap[child] <= value) break;
        heap[i] = heap[child]; i = child;
    }
    heap[i] = value;
}
fn long slope_trick_lipschitz_l1(long* input, usz length) @export("slope_trick_lipschitz_l1") {
    if (input == null || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > 100) return -1;
    usz n = (usz)input[0];
    if (length != n+2) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] > 100) return -1;
    long[128] left = {}, right = {};
    long shift_l = 0, shift_r = 0, answer = 0;
    usz ln = 0, rn = 0;
    for (usz i = 0; i < n; i++) {
        shift_l -= input[1]; shift_r += input[1];
        heap_push(&left[0], &ln, input[2+i]-shift_l);
        heap_push(&right[0], &rn, shift_r-input[2+i]);
        long l = left[0]+shift_l, r = shift_r-right[0];
        if (l > r) {
            answer += l-r;
            heap_replace(&left[0], ln, r-shift_l);
            heap_replace(&right[0], rn, shift_r-l);
        }
    }
    return answer;
}
