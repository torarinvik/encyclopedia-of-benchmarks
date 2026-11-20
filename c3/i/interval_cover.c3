module interval_cover;

fn long interval_cover(long* input, usz length) @export("interval_cover") {
    if (input == null || length < 3 || length > 36) return -2;
    long target_left = input[0];
    long target_right = input[1];
    long count_value = input[2];
    if (target_left < 0 || target_left > target_right || target_right > 32
        || count_value < 0 || count_value > 16) return -2;
    usz count = (usz)count_value;
    if (length != 3 + 2 * count) return -2;
    for (usz i = 0; i < count; i++) {
        long left = input[3 + 2 * i];
        long right = input[4 + 2 * i];
        if (left < 0 || left >= right || right > 32) return -2;
    }
    if (target_left == target_right) return 0;

    long frontier = target_left;
    long selected = 0;
    while (frontier < target_right) {
        long farthest = frontier;
        for (usz i = 0; i < count; i++) {
            long left = input[3 + 2 * i];
            long right = input[4 + 2 * i];
            if (left <= frontier && right > farthest) farthest = right;
        }
        if (farthest == frontier) return -1;
        frontier = farthest;
        selected++;
    }
    return selected;
}
