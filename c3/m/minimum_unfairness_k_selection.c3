module minimum_unfairness_k_selection;

const usz MAX_N = 64;
const long MIN_VALUE = -1000000000;
const long MAX_VALUE = 1000000000;

fn void muks_sift_down(long* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void muks_heap_sort(long* values, usz length) {
    for (usz start = length / 2; start > 0; start--) {
        muks_sift_down(values, start - 1, length);
    }
    for (usz end = length; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        muks_sift_down(values, 0, end - 1);
    }
}

fn long minimum_unfairness_k_selection(long* packed, usz length)
    @export("minimum_unfairness_k_selection") {
    if (packed == null || length < 4 || length > MAX_N + 2) return -1;
    long n_value = packed[0];
    long k_value = packed[1];
    if (n_value < 2 || n_value > (long)MAX_N || k_value < 2 || k_value > n_value ||
        length != (usz)n_value + 2) return -1;

    usz n = (usz)n_value;
    usz k = (usz)k_value;
    long[MAX_N] sorted;
    for (usz index = 0; index < n; index++) {
        long value = packed[index + 2];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        sorted[index] = value;
    }
    muks_heap_sort(&sorted[0], n);

    long best = 2000000001;
    for (usz first = 0; first + k <= n; first++) {
        long width = sorted[first + k - 1] - sorted[first];
        if (width < best) best = width;
    }
    return best;
}
