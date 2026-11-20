module interpolation_sequential_search;

const usz MAX_N = 64;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;

fn long interpolation_sequential_search(long* input, usz length) @export("interpolation_sequential_search") {
    if (input == null || length < 2 || length > MAX_N + 3) return -1;
    long count_value = input[0];
    long target = input[1];
    if (count_value < 0 || count_value > (long)MAX_N || length != (usz)count_value + 2
            || target < MIN_VALUE || target > MAX_VALUE) return -1;
    usz count = (usz)count_value;
    for (usz i = 0; i < count; i++) {
        long value = input[i + 2];
        if (value < MIN_VALUE || value > MAX_VALUE || (i > 0 && input[i + 1] >= value)) return -1;
    }
    if (count == 0) return -1;
    long first = input[2];
    long last = input[count + 1];
    if (target < first || target > last) return -1;
    if (count == 1) return first == target ? 0 : -1;
    usz position = (usz)(((target - first) * (long)(count - 1)) / (last - first));
    long estimated = input[position + 2];
    if (estimated == target) return (long)position;
    if (estimated < target) {
        for (usz i = position + 1; i < count; i++) {
            long value = input[i + 2];
            if (value >= target) return value == target ? (long)i : -1;
        }
    } else {
        usz i = position;
        while (i > 0) {
            i--;
            long value = input[i + 2];
            if (value <= target) return value == target ? (long)i : -1;
        }
    }
    return -1;
}
