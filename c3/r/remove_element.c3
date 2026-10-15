module remove_element;

const MAX_LENGTH = 4096;

// Remove every occurrence of target while preserving the surviving order.
fn long remove_element(long* input, usz length, char* output,
        usz output_capacity) @export("remove_element") {
    if (length == 0 || length > MAX_LENGTH || input == null) { return -1; }
    long target = input[0];
    if (target < -2147483648L || target > 2147483647L) { return -1; }
    usz survivor_count = 0;
    for (usz index = 1; index < length; index++) {
        long value = input[index];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        if (value != target) { survivor_count++; }
    }
    usz output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    usz written = 0;
    for (usz index = 1; index < length; index++) {
        if (input[index] != target) {
            uint bits = (uint)(int)input[index];
            for (usz byte = 0; byte < 4; byte++) {
                output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
            }
            written++;
        }
    }
    return written == survivor_count ? (long)written : -1;
}
