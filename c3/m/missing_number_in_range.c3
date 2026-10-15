module missing_number_in_range;

const usz MAX_VALUES = 1024;
const long INVALID_RESULT = -2147483649;

fn ulong encode_i32(long value) {
    return (ulong)(value < 0 ? value + 4294967296 : value);
}

fn long missing_number_in_range(long* values, usz length) @export("missing_number_in_range") {
    if (values == null || length < 2 || length > MAX_VALUES) return INVALID_RESULT;
    long low = values[0];
    long high = values[0];
    for (usz i = 0; i < length; i++) {
        if (values[i] < -2147483648 || values[i] > 2147483647) return INVALID_RESULT;
        if (values[i] < low) low = values[i];
        if (values[i] > high) high = values[i];
    }
    if (high - low != (long)length) return INVALID_RESULT;
    bool[MAX_VALUES + 1] seen;
    ulong actual = 0;
    for (usz i = 0; i < length; i++) {
        usz slot = (usz)(values[i] - low);
        if (seen[slot]) return INVALID_RESULT;
        seen[slot] = true;
        actual ^= encode_i32(values[i]);
    }
    ulong expected = 0;
    for (long value = low; value <= high; value++) expected ^= encode_i32(value);
    ulong result = expected ^ actual;
    return result <= 2147483647 ? (long)result : (long)result - 4294967296;
}
