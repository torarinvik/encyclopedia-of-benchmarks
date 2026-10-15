module swap_pairs;

const MAX_LENGTH = 1024;

// Swap adjacent node values in a bounded array representation of a list.
fn long swap_pairs(long* input, usz length, char* output,
        usz output_capacity) @export("swap_pairs") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return -1; }
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648L || input[index] > 2147483647L) { return -1; }
    }
    usz output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }

    for (usz index = 0; index < length; index++) {
        usz pair_start = (index / 2) * 2;
        usz source_index = pair_start;
        if (index % 2 == 0 && pair_start + 1 < length) { source_index = pair_start + 1; }
        uint bits = (uint)(int)input[source_index];
        for (usz byte = 0; byte < 4; byte++) {
            output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)length;
}
