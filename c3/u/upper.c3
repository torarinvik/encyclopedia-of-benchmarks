module upper;

const MAX_LENGTH = 256;

fn long upper(long* input, usz length, char* output, usz capacity) @export("upper") {
    if (length > MAX_LENGTH || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127 || input[i] == 9 || input[i] == 10 || input[i] == 11 || input[i] == 12 || input[i] == 13 || input[i] == 32) return -1;
    if (capacity < length || (length > 0 && output == null)) return -2;
    for (usz i = 0; i < length; i++) output[i] = (char)input[i];
    for (usz i = 0; i < length; i++) if (output[i] >= 'a' && output[i] <= 'z') output[i] -= 32;
    return (long)length;
}
