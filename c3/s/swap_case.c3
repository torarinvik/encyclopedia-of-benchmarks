module swap_case;

const usz MAX_INPUT_LENGTH = 4096;

fn long swap_case(long* input, usz length, char* output, usz capacity) @export("swap_case") {
    if (length > MAX_INPUT_LENGTH || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }
    if (length > capacity || (length > 0 && output == null)) return -2;
    for (usz i = 0; i < length; i++) {
        long value = input[i];
        if (value >= 65 && value <= 90) value += 32;
        else if (value >= 97 && value <= 122) value -= 32;
        output[i] = (char)value;
    }
    return (long)length;
}
