module number_appearing_odd_times;

const usz MAX_LENGTH = 4096;
const long INVALID_RESULT = -2147483649L;

// XOR-fold an int32 array to find its unique odd-frequency value.
fn long number_appearing_odd_times(long* values, usz length) @export("number_appearing_odd_times") {
    if (length == 0 || length > MAX_LENGTH || values == null) return INVALID_RESULT;
    int result = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < -2147483648L || value > 2147483647L) return INVALID_RESULT;
        result ^= (int)value;
    }
    return (long)result;
}
