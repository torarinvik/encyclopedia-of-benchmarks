module atbash_cipher;

// Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence.
fn long atbash_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("atbash_cipher") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 65 && value <= 90) {
            mapped = 155 - value;
        } else if (value >= 97 && value <= 122) {
            mapped = 219 - value;
        }
        output[index] = (char)mapped;
    }
    return (long)length;
}
