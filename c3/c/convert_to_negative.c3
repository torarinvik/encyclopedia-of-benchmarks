module convert_to_negative;

fn long convert_to_negative(long* values, usz length, char* output, usz output_capacity) @export("convert_to_negative") {
    if (values == null || length < 1 || length > 4096) return -1;
    long count = values[0];
    if (count < 0 || count > 4095 || (usz)count != length - 1) return -1;
    for (usz index = 0; index < (usz)count; index++) {
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    }
    if ((usz)count > output_capacity || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < (usz)count; index++) {
        output[index] = (char)(255 - values[index + 1]);
    }
    return count;
}
