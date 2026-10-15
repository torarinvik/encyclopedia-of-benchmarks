module is_uppercase;

const usz MAX_LENGTH = 4096;

fn long is_uppercase(long* values, usz length) @export("is_uppercase") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 97 && value <= 122) return 0;
    }
    return 1;
}
