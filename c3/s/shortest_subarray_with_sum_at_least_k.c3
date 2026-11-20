module shortest_subarray_with_sum_at_least_k;

const usz MAX_COUNT = 256;
const usz MAX_INPUT = 259;

fn long shortest_subarray_with_sum_at_least_k(long* packed, usz length)
        @export("shortest_subarray_with_sum_at_least_k") {
    if (packed == null || length < 2 || length > MAX_INPUT) return -1;
    long target = packed[0], count = packed[1];
    if (target < -4096 || target > 4096 || count < 0 || count > (long)MAX_COUNT ||
        length != (usz)count + 2) return -1;

    long[MAX_COUNT + 1] prefix = zeroed;
    for (long index = 0; index < count; index += 1) {
        long value = packed[index + 2];
        if (value < -1000 || value > 1000) return -1;
        prefix[index + 1] = prefix[index] + value;
    }

    long[MAX_COUNT + 1] deque = zeroed;
    usz head = 0, tail = 0;
    long best = count + 1;
    for (usz right = 0; right <= (usz)count; right += 1) {
        while (head < tail && prefix[right] - prefix[(usz)deque[head]] >= target) {
            long width = (long)right - deque[head];
            if (width < best) best = width;
            head += 1;
        }
        while (head < tail && prefix[right] <= prefix[(usz)deque[tail - 1]]) {
            tail -= 1;
        }
        deque[tail] = (long)right;
        tail += 1;
    }
    return best <= count ? best : 0;
}

