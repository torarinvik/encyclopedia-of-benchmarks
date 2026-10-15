module missing_number;

// Return the absent value from the inclusive range 0 through array length.
const usz MAX_VALUES = 1024;

fn long missing_number(long* values, usz length) @export("missing_number") {
    if (length > MAX_VALUES || (length != 0 && values == null)) return -1;
    bool[MAX_VALUES + 1] seen;
    long actual_sum = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 0 || value > (long)length || seen[value]) return -1;
        seen[value] = true;
        actual_sum += value;
    }
    long n = (long)length;
    return n * (n + 1) / 2 - actual_sum;
}
