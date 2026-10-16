module partition_problem;

const usz MAX_ITEMS = 16;
const usz MAX_TOTAL = 1024;

fn long partition_problem(long* input, usz length) @export("partition_problem") {
    if (input == null || length == 0 || length > MAX_ITEMS) return -1;
    long total = 0;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 256 || total > 1024 - input[index]) return -1;
        total += input[index];
    }
    if ((total & 1) != 0) return 0;
    usz target = (usz)(total / 2);
    long[MAX_TOTAL + 1] reachable;
    for (usz index = 0; index <= MAX_TOTAL; index++) reachable[index] = 0;
    reachable[0] = 1;
    for (usz index = 0; index < length; index++) {
        usz value = (usz)input[index];
        if (value > target) continue;
        usz sum = target;
        while (sum >= value) {
            if (reachable[sum - value] != 0) reachable[sum] = 1;
            if (sum == value) break;
            sum--;
        }
    }
    return reachable[target];
}
