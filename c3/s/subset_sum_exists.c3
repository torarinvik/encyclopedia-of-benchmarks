module subset_sum_exists;

// Decide whether a signed integer subset reaches the requested sum.
fn long subset_sum_exists(long* input, usz length) @export("subset_sum_exists")
{
    if (length == 0 || length > 25) return -1;
    long target = input[0];
    if (target < -6144 || target > 6144) return -1;
    for (usz index = 1; index < length; index++) {
        if (input[index] < -256 || input[index] > 256) return -1;
    }
    bool[12289] reachable;
    for (usz index = 0; index < 12289; index++) reachable[index] = false;
    reachable[6144] = true;
    long low = 0;
    long high = 0;
    for (usz index = 1; index < length; index++) {
        long value = input[index];
        if (value > 0) {
            for (long sum = high; sum >= low; sum--) {
                if (reachable[(usz)(sum + 6144)]) reachable[(usz)(sum + value + 6144)] = true;
            }
            high += value;
        } else if (value < 0) {
            for (long sum = low; sum <= high; sum++) {
                if (reachable[(usz)(sum + 6144)]) reachable[(usz)(sum + value + 6144)] = true;
            }
            low += value;
        }
    }
    return reachable[(usz)(target + 6144)] ? 1 : 0;
}
