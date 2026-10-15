module subset_sum_dynamic;

const usz MAX_ITEMS = 16;
const usz WIDTH = 801;
const usz STATES = 17 * WIDTH;

fn long subset_sum_dynamic_search(long* input, usz item_count, usz index,
                                  long remaining, long* memo) {
    if (remaining == 0) return 1;
    if (index == item_count) return 0;
    usz state = index * WIDTH + (usz)(remaining + 400);
    if (memo[state] != -2) return memo[state];
    long result = subset_sum_dynamic_search(input, item_count, index + 1,
                                            remaining - input[index + 1], memo);
    if (result == 0) result = subset_sum_dynamic_search(input, item_count, index + 1, remaining, memo);
    memo[state] = result;
    return result;
}

fn long subset_sum_dynamic(long* input, usz length) @export("subset_sum_dynamic") {
    if (input == null || length == 0 || length > MAX_ITEMS + 1) return -1;
    long target = input[0];
    if (target < -80 || target > 80) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < -20 || input[i] > 20) return -1;
    long[STATES] memo;
    for (usz i = 0; i < STATES; i++) memo[i] = -2;
    return subset_sum_dynamic_search(input, length - 1, 0, target, memo);
}
