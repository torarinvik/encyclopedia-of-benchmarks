module fast_searcher;

const usz MAX_ARRAY_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 67;

fn long search_segment(long* values, usz begin, usz length, long target, usz offset) {
    if (length == 0) return -1;
    long first = values[begin];
    long last = values[begin + length - 1];
    if (target < first || target > last) return -1;
    if (first == last) return target == first ? (long)offset : -1;

    usz interpolation = (usz)((long)(length - 1) * (target - first) / (last - first));
    usz midpoint = length / 2;
    usz left = interpolation > midpoint ? midpoint : interpolation;
    usz right = interpolation > midpoint ? interpolation : midpoint;
    usz from, to;
    if (target < values[begin + left]) {
        if (left == 0) return -1;
        from = 0;
        to = left - 1;
    } else if (target < values[begin + right]) {
        from = left;
        to = right - 1;
    } else {
        from = right;
        to = length - 1;
    }
    if (to < from) return -1;
    return search_segment(values, begin + from, to - from + 1, target, offset + from);
}

fn long fast_searcher(long* input, usz length) @export("fast_searcher") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -2;
    if (input[0] < 0 || input[0] > (long)MAX_ARRAY_LENGTH) return -2;
    usz count = (usz)input[0];
    if (length != count + 2) return -2;
    for (usz i = 0; i < count; i++) {
        long value = input[1 + i];
        if (value < -1000 || value > 1000) return -2;
        if (i > 0 && input[i] >= value) return -2;
    }
    long target = input[length - 1];
    if (target < -1000 || target > 1000) return -2;
    return search_segment(input, 1, count, target, 0);
}
