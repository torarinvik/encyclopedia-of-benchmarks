module remove_boxes;

const usz MAX_BOXES = 18;
const usz MAX_PARSEABLE_LENGTH = MAX_BOXES + 2;
const usz MAX_MEMO = MAX_BOXES * MAX_BOXES * (MAX_BOXES + 1);

fn long solve_boxes(usz left, usz right, usz carry, long* colors,
                    usz* counts, long* memo) {
    if (left > right) return 0;
    usz index = (left * MAX_BOXES + right) * (MAX_BOXES + 1) + carry;
    if (memo[index] >= 0) return memo[index];
    usz attached = counts[left] + carry;
    long score = (long)(attached * attached);
    long best = score + solve_boxes(left + 1, right, 0, colors, counts, memo);
    for (usz later = left + 1; later <= right; later++) {
        if (colors[later] == colors[left]) {
            long joined = solve_boxes(left + 1, later - 1, 0, colors, counts, memo)
                + solve_boxes(later, right, attached, colors, counts, memo);
            if (joined > best) best = joined;
        }
    }
    memo[index] = best;
    return best;
}

fn long remove_boxes(long* values, usz length) @export("remove_boxes") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_raw = values[0];
    if (n_raw < 0 || n_raw > (long)MAX_BOXES || length != (usz)n_raw + 1) return -1;
    usz n = (usz)n_raw;
    long[MAX_BOXES] colors = zeroed;
    usz[MAX_BOXES] counts = zeroed;
    usz groups = 0;
    for (usz i = 0; i < n; i++) {
        long color = values[i + 1];
        if (color < 0 || color > 7) return -1;
        if (groups > 0 && colors[groups - 1] == color) {
            counts[groups - 1] += 1;
        } else {
            colors[groups] = color;
            counts[groups] = 1;
            groups += 1;
        }
    }
    if (groups == 0) return 0;
    long[MAX_MEMO] memo;
    for (usz i = 0; i < MAX_MEMO; i++) memo[i] = -1;
    return solve_boxes(0, groups - 1, 0, &colors[0], &counts[0], &memo[0]);
}
