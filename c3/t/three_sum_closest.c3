module three_sum_closest;

const usz MAX_ITEMS = 512;
const long INVALID_RESULT = -9000000000000000000;

fn void heap_sift_down(long* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* values, usz length) {
    for (usz start = length / 2; start > 0; start--) heap_sift_down(values, start - 1, length);
    for (usz end = length; end > 1; end--) {
        long temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        heap_sift_down(values, 0, end - 1);
    }
}

fn long absolute_difference(long left, long right) {
    long difference = left - right;
    if (difference < 0) return -difference;
    return difference;
}

fn long three_sum_closest(long* input, usz length) @export("three_sum_closest") {
    if (input == null || length < 2 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    long target = input[0];
    long count_value = input[1];
    if (target < -2147483648 || target > 2147483647 || count_value < 3 || count_value > 512) { return INVALID_RESULT; }
    usz count = (usz)count_value;
    if (length != count + 2) return INVALID_RESULT;
    long[MAX_ITEMS] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < -2147483648 || value > 2147483647) return INVALID_RESULT;
        values[index] = value;
    }
    heap_sort(&values[0], count);
    long best = values[0] + values[1] + values[2];
    long best_difference = absolute_difference(target, best);
    for (usz first = 0; first + 2 < count; first++) {
        usz left = first + 1;
        usz right = count - 1;
        while (left < right) {
            long sum = values[first] + values[left] + values[right];
            long difference = absolute_difference(target, sum);
            if (difference < best_difference || (difference == best_difference && sum < best)) {
                best = sum; best_difference = difference;
            }
            if (sum < target) { left++; }
            else if (sum > target) { right--; }
            else { return sum; }
        }
    }
    return best;
}
