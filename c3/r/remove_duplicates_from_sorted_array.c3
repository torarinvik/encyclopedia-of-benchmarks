module remove_duplicates_array;

const MAX_LENGTH = 4096;

// Compact each value in an ascending array to its first occurrence.
fn long remove_duplicates_from_sorted_array(long* input, usz length, char* output,
        usz output_capacity) @export("remove_duplicates_from_sorted_array") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return -1; }
    usz unique_count = 0;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value < -2147483648L || value > 2147483647L ||
            (index != 0 && input[index - 1] > value)) { return -1; }
        if (index == 0 || input[index - 1] != value) { unique_count++; }
    }
    usz output_bytes = unique_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    usz written = 0;
    for (usz index = 0; index < length; index++) {
        if (index == 0 || input[index - 1] != input[index]) {
            uint bits = (uint)(int)input[index];
            for (usz byte = 0; byte < 4; byte++) {
                output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
            }
            written++;
        }
    }
    return written == unique_count ? (long)written : -1;
}
