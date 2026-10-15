module check_pascal_case;

const usz MAX_LENGTH = 4096;

// Check the bounded ASCII Pascal-case predicate.
fn long check_pascal_case(long* values, usz length) @export("check_pascal_case") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -2;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 32 || values[i] > 126) return -2;
    }
    if (length == 0 || values[0] < 65 || values[0] > 90) return 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (!((value >= 97 && value <= 122) || (value >= 65 && value <= 90))) return 0;
    }
    return 1;
}
