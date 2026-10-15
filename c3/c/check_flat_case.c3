module check_flat_case;

const usz MAX_LENGTH = 4096;

// Check whether the bounded ASCII input is entirely lowercase letters.
fn long check_flat_case(long* values, usz length) @export("check_flat_case") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -2;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 32 || value > 126) return -2;
    }
    for (usz i = 0; i < length; i++) {
        if (values[i] < 97 || values[i] > 122) return 0;
    }
    return 1;
}
