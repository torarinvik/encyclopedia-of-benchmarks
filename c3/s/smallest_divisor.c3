module smallest_divisor;

// Find the least positive divisor whose rounded sum fits the threshold.
fn long smallest_divisor(long* input, usz length) @export("smallest_divisor") {
    if (length < 2 || length > 257 || input == null) return -1;
    long threshold = input[0];
    if (threshold < 1 || threshold > 1000000) return -1;
    long maximum = 0;
    for (usz index = 1; index < length; index++) {
        long value = input[index];
        if (value < 1 || value > 1000000) return -1;
        if (value > maximum) maximum = value;
    }
    usz count = length - 1;
    if (threshold < (long)count) return -1;
    long low = 1;
    long high = maximum;
    while (low < high) {
        long middle = low + (high - low) / 2;
        long sum = 0;
        for (usz index = 1; index < length; index++) {
            sum += (input[index] + middle - 1) / middle;
        }
        if (sum <= threshold) { high = middle; }
        else { low = middle + 1; }
    }
    return low;
}
