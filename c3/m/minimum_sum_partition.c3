module minimum_sum_partition;

const usz MAX_VALID_INPUT_LENGTH = 64;
const usz MAX_TOTAL_SUM = 4096;
const long MAX_TOTAL_SUM_I64 = 4096;

fn long minimum_sum_partition(long* input, usz length) @export("minimum_sum_partition") {
    if (length > MAX_VALID_INPUT_LENGTH || (input == null && length != 0)) return -1;

    long total = 0;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value < 0 || value > MAX_TOTAL_SUM_I64 || total > MAX_TOTAL_SUM_I64 - value) return -1;
        total += value;
    }

    usz target = (usz)(total / 2);
    u8[MAX_TOTAL_SUM / 2 + 1] reachable = zeroed;
    reachable[0] = 1;
    usz closest = 0;
    for (usz index = 0; index < length; index++) {
        usz value = (usz)input[index];
        for (usz sum = target; sum > 0; sum--) {
            if (value <= sum && reachable[sum - value] != 0) reachable[sum] = 1;
            if (reachable[sum] != 0 && sum > closest) closest = sum;
        }
    }
    return total - 2 * (long)closest;
}
