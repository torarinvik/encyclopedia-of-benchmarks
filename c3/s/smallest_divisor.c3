module smallest_divisor;

// Find the least positive divisor whose rounded sum fits the threshold.
fn long smallest_divisor(long* input, usz length) @export("smallest_divisor") {
    if (length < 2 || length > 257 || input == null) return -1;
    ulong count = (ulong)(length - 1);
    ulong threshold = (ulong)input[0];
    if (threshold < count || threshold > 1000000) return -1;
    ulong maximum = 0;
    ulong total = 0;
    for (usz index = 1; index < length; index++) {
        ulong value = (ulong)input[index];
        if (value == 0 || value > 1000000) return -1;
        maximum = value > maximum ? value : maximum;
        total += value;
    }
    if (threshold == count) return (long)maximum;

    ulong low = (total - 1) / threshold + 1;
    ulong upper_bound = (total - count) / (threshold - count + 1) + 1;
    ulong high = upper_bound < maximum ? upper_bound : maximum;
    while (low < high) {
        ulong middle = low + ((high - low) >> 1);
        ulong rounded_sum = count;
        if (count <= 4) {
            for (usz index = 1; index < length; index++) {
                rounded_sum += (ulong)(((uint)input[index] - 1) / (uint)middle);
            }
        } else {
            ulong reciprocal = (1099511627775 / middle) + 1;
            for (usz index = 1; index < length; index++) {
                rounded_sum += (((ulong)input[index] - 1) * reciprocal) >> 40;
            }
        }
        if (rounded_sum <= threshold) { high = middle; }
        else { low = middle + 1; }
    }
    return (long)low;
}
