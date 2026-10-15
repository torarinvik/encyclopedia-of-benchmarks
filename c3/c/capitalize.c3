module capitalize;

const MAX_LENGTH = 256;

fn long capitalize(long* input, usz length, char* output, usz capacity) @export("capitalize") {
    if (length > MAX_LENGTH || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127) return -1;
    if (capacity < length || (length > 0 && output == null)) return -2;
    for (usz i = 0; i < length; i++) output[i] = (char)input[i];
    if (length > 0 && output[0] >= 'a' && output[0] <= 'z') output[0] -= 32;
    return (long)length;
}
