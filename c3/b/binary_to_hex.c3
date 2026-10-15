module binary_to_hex;

const usz MAX_LENGTH = 4096;

fn long binary_to_hex(long* values, usz length, char* output, usz output_capacity)
    @export("binary_to_hex")
{
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] != '0' && values[i] != '1') return -1;
    }

    usz output_length = (length + 3) / 4;
    if (output_length == 0) return 0;
    if (output == null || output_capacity < output_length) return -2;

    usz first_width = length % 4;
    if (first_width == 0) first_width = 4;
    usz start = 0;
    for (usz group = 0; group < output_length; group++) {
        usz width = 4;
        if (group == 0) width = first_width;
        long nibble = 0;
        for (usz offset = 0; offset < width; offset++) {
            nibble = nibble * 2 + (values[start + offset] - '0');
        }
        if (nibble < 10) {
            output[group] = (char)('0' + nibble);
        } else {
            output[group] = (char)('A' + nibble - 10);
        }
        start += width;
    }
    return (long)output_length;
}
