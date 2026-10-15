module check_snake_case;

const usz MAX_LENGTH = 4096;

fn long check_snake_case(long* values, usz length) @export("check_snake_case") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -2;
    long found = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 32 || value > 126) return -2;
        if (value == 95) found = 1;
    }
    return found;
}
