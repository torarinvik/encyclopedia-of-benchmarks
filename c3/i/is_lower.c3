module is_lower;

const usz MAX_LENGTH = 4096;

fn long is_lower(long* values, usz length) @export("is_lower") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 65 && value <= 90) return 0;
    }
    return 1;
}
