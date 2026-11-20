module erdos_gallai_graphical_sequence;

const long MAX_N = 256;
const usz MAX_PARSEABLE_LENGTH = 258;

fn void sift_down(long* values, long root, long end) {
    while (root * 2 + 1 < end) {
        long child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) return;
        long temp = values[root];
        values[root] = values[child];
        values[child] = temp;
        root = child;
    }
}

fn void sort_descending(long* values, long count) {
    if (count < 2) return;
    long start = count / 2;
    while (start > 0) {
        start--;
        sift_down(values, start, count);
    }
    long end = count;
    while (end > 1) {
        end--;
        long temp = values[end];
        values[end] = values[0];
        values[0] = temp;
        sift_down(values, 0, end);
    }
    long left = 0;
    long right = count - 1;
    while (left < right) {
        long temp = values[left];
        values[left] = values[right];
        values[right] = temp;
        left++;
        right--;
    }
}

fn long erdos_gallai_graphical_sequence(long* input, usz length)
    @export("erdos_gallai_graphical_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n = input[0];
    if (n < 0 || n > MAX_N || length != (usz)n + 1) return -1;

    long[MAX_N] degrees;
    long[MAX_N + 1] prefix;
    prefix[0] = 0;
    long sum = 0;
    for (long i = 0; i < n; ++i) {
        long degree = input[i + 1];
        if (degree < 0 || degree >= n) return -1;
        degrees[i] = degree;
        sum += degree;
    }
    if (sum % 2 != 0) return 0;
    if (n == 0) return 1;

    sort_descending(&degrees[0], n);
    for (long i = 0; i < n; ++i) prefix[i + 1] = prefix[i] + degrees[i];

    for (long k = 1; k <= n; ++k) {
        long low = k;
        long high = n;
        while (low < high) {
            long mid = low + (high - low) / 2;
            if (degrees[mid] >= k) low = mid + 1;
            else high = mid;
        }
        long split = low;
        long rhs = k * (k - 1) + (split - k) * k + (prefix[n] - prefix[split]);
        if (prefix[k] > rhs) return 0;
    }
    return 1;
}
