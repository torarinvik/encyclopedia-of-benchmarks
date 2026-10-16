module monotonic_array;

fn long is_monotonic(long* values, ulong length) @export("is_monotonic") {
    if (length > 256 || (values == null && length != 0)) {
        return -1;
    }
    for (ulong i = 1; i < length; i++) {
        if (values[i - 1] > values[i]) {
            for (ulong j = 1; j < length; j++) {
                if (values[j - 1] < values[j]) {
                    return 0;
                }
            }
            return 1;
        }
    }
    return 1;
}
