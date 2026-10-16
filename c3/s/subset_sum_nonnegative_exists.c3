module subset_sum_nonnegative_exists;

const usz MAX_ITEMS = 64;
const long MAX_TARGET = 4096;
const usz WIDTH = 4097;

fn long subset_sum_nonnegative_exists(long* input, usz length) @export("subset_sum_nonnegative_exists") {
    if (input == null || length == 0 || length > MAX_ITEMS + 1) return -1;
    long target = input[0];
    if (target < 0 || target > MAX_TARGET) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > MAX_TARGET) return -1;
    bool[WIDTH] reachable;
    for (usz i = 0; i < WIDTH; i++) reachable[i] = false;
    reachable[0] = true;
    for (usz i = 1; i < length; i++) {
        long item = input[i];
        long sum = target;
        while (sum >= item) {
            if (reachable[(usz)(sum - item)]) reachable[(usz)sum] = true;
            sum--;
        }
    }
    return reachable[(usz)target] ? 1 : 0;
}
