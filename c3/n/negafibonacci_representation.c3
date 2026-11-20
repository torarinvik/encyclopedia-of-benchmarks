module negafibonacci_representation;

const usz MAX_INDEX = 17;
const long VALUE_LIMIT = 1000;

fn long encode(long value, char* output) {
    long[MAX_INDEX + 1] fib = zeroed;
    long[MAX_INDEX + 1] weight = zeroed;
    long[MAX_INDEX + 1] low = zeroed;
    long[MAX_INDEX + 1] high = zeroed;
    bool[MAX_INDEX + 1] digit = zeroed;
    fib[1] = 1; fib[2] = 1;
    for (usz k = 3; k <= MAX_INDEX; k++) fib[k] = fib[k - 1] + fib[k - 2];
    for (usz k = 1; k <= MAX_INDEX; k++) {
        weight[k] = fib[k];
        if (k % 2 == 0) weight[k] = -fib[k];
    }
    for (usz k = 1; k <= MAX_INDEX; k++) {
        long suffix_low = 0, suffix_high = 0;
        if (k > 1) { suffix_low = low[k - 2]; suffix_high = high[k - 2]; }
        long with_low = weight[k] + suffix_low;
        long with_high = weight[k] + suffix_high;
        low[k] = low[k - 1] < with_low ? low[k - 1] : with_low;
        high[k] = high[k - 1] > with_high ? high[k - 1] : with_high;
    }
    long remaining = value;
    bool selected_above = false;
    for (usz k = MAX_INDEX; k > 0; k--) {
        bool choose = false;
        if (!selected_above) {
            long suffix_low = 0, suffix_high = 0;
            if (k > 1) { suffix_low = low[k - 2]; suffix_high = high[k - 2]; }
            long candidate = remaining - weight[k];
            choose = suffix_low <= candidate && candidate <= suffix_high;
        }
        if (choose) { digit[k] = true; remaining -= weight[k]; }
        selected_above = choose;
    }
    usz highest = MAX_INDEX;
    while (highest > 1 && !digit[highest]) highest--;
    for (usz k = highest; k > 0; k--) output[highest - k] = digit[k] ? '1' : '0';
    return (long)highest;
}

fn long negafibonacci_representation(long* input, usz length, char* output, usz output_capacity)
    @export("negafibonacci_representation") {
    if (input == null || length != 1 || input[0] < -VALUE_LIMIT || input[0] > VALUE_LIMIT) return -1;
    char[MAX_INDEX] staged = zeroed;
    usz required = (usz)encode(input[0], &staged[0]);
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < required; index++) output[index] = staged[index];
    return (long)required;
}
