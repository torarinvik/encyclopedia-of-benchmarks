module to_lower_case;

const usz MAX_LENGTH = 4096;

// Lowercase ASCII bytes without locale-dependent character handling.
fn long to_lower_case(long* input, usz length, char* output, usz output_capacity) @export("to_lower_case") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return -1; }
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 127) { return -1; }
    }
    if (output_capacity < length) { return -2; }
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value >= 65 && value <= 90) { value = value + 32; }
        output[index] = (char)value;
    }
    return (long)length;
}
