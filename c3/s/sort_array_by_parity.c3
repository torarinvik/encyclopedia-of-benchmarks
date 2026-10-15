module sort_array_by_parity;

const usz MAX_ARRAY_LENGTH = 5000;

// Place evens first and fill the odd section from its end.
fn long sort_array_by_parity(long* input, usz length, char* output,
                             usz output_capacity) @export("sort_array_by_parity") {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == null)) { return -1; }
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 5000) { return -1; }
    }
    usz output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }

    usz even_index = 0;
    usz odd_index = length;
    for (usz index = 0; index < length; index++) {
        ulong value = (ulong)input[index];
        usz destination;
        if ((value & 1) == 0) {
            destination = even_index;
            even_index++;
        } else {
            odd_index--;
            destination = odd_index;
        }
        for (usz byte = 0; byte < 4; byte++) {
            output[destination * 4 + byte] = (char)((value >> (byte * 8)) & 255);
        }
    }
    return (long)length;
}
