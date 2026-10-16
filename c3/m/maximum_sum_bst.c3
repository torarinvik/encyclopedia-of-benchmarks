module maximum_sum_bst;

const usz MAX_SLOTS = 31;
const long MAX_VALUE = 1000000;
const long EMPTY_MIN = 1000001;

fn long maximum_sum_bst(long* input, usz length) @export("maximum_sum_bst") {
    if (input == null || length < 1 || length > 32) return -1;
    if (input[0] < 0 || input[0] > 31 || length != input[0].usz() + 1) return -1;
    usz count = input[0].usz();
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] < -1 || input[i + 1] > MAX_VALUE) return -1;
        if (input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1) return -1;
    }
    if (count == 0) return 0;
    bool[MAX_SLOTS] valid;
    long[MAX_SLOTS] subtree_min;
    long[MAX_SLOTS] subtree_max;
    long[MAX_SLOTS] subtree_sum;
    long[MAX_SLOTS] best;
    usz remaining = count;
    while (remaining > 0) {
        remaining--;
        usz i = remaining;
        if (input[i + 1] == -1) {
            valid[i] = true; subtree_min[i] = EMPTY_MIN; subtree_max[i] = -1;
            subtree_sum[i] = 0; best[i] = 0; continue;
        }
        usz left = 2 * i + 1; usz right = left + 1;
        bool left_valid = left >= count || valid[left];
        bool right_valid = right >= count || valid[right];
        long left_max = left >= count ? -1 : subtree_max[left];
        long right_min = right >= count ? EMPTY_MIN : subtree_min[right];
        long left_min = left >= count ? EMPTY_MIN : subtree_min[left];
        long right_max = right >= count ? -1 : subtree_max[right];
        long left_sum = left >= count ? 0 : subtree_sum[left];
        long right_sum = right >= count ? 0 : subtree_sum[right];
        long left_best = left >= count ? 0 : best[left];
        long right_best = right >= count ? 0 : best[right];
        long value = input[i + 1];
        if (left_valid && right_valid && left_max < value && value < right_min) {
            valid[i] = true;
            subtree_min[i] = left_min < value ? left_min : value;
            subtree_max[i] = right_max > value ? right_max : value;
            subtree_sum[i] = left_sum + right_sum + value;
            best[i] = subtree_sum[i] > left_best ? subtree_sum[i] : left_best;
            if (right_best > best[i]) best[i] = right_best;
        } else {
            valid[i] = false; subtree_min[i] = 0; subtree_max[i] = 0; subtree_sum[i] = 0;
            best[i] = left_best > right_best ? left_best : right_best;
        }
    }
    return best[0];
}
