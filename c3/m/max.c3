module max;

fn long max_values(long* values, usz length) @export("max_values") {
    if (values == null || length < 1 || length > 257) return -9223372036854775807L - 1;
    long count = values[0];
    if (count < 1 || count > 256 || length != (usz)count + 1) return -9223372036854775807L - 1;
    long result = values[1];
    if (result < -2147483648L || result > 2147483647L) return -9223372036854775807L - 1;
    for (usz index = 2; index < length; index++) {
        long value = values[index];
        if (value < -2147483648L || value > 2147483647L) return -9223372036854775807L - 1;
        if (value > result) result = value;
    }
    return result;
}
