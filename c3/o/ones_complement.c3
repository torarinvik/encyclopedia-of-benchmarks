module ones_complement;

const usz MAX_INPUT_LENGTH = 64;

fn long ones_complement(long* input, usz length, char* output, usz capacity) @export("ones_complement") {
    if (length == 0 || length > MAX_INPUT_LENGTH || input == null) return -1;
    for (usz i = 0; i < length; i++) {
        if (input[i] != 48 && input[i] != 49) return -1;
    }
    if (length > capacity || output == null) return -2;
    for (usz i = 0; i < length; i++) {
        output[i] = if input[i] == 48 then 49 else 48;
    }
    return (long)length;
}
