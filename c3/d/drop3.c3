module drop3;

const usz MAX_INPUT = 4096;
const usz[8] OFFSETS = {0, 5, 2, 7, 4, 1, 6, 3};

fn long drop3(long* values, usz length) @export("drop3") {
    if (length > MAX_INPUT + 1 || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (length > MAX_INPUT) return -1;

    long output_size = 0;
    for (usz iteration = 0; iteration < 20; iteration++) {
        usz input_index = 0;
        usz remaining_bits = length * 8;
        usz phase = 0;
        ushort bit_buffer = 0;
        long output_bits = 0;
        while (remaining_bits >= 3) {
            remaining_bits -= 3;
            usz offset = OFFSETS[phase];
            if (offset < 3) {
                uint16 shifted = (uint16)values[input_index] << (8 - offset);
                bit_buffer = (ushort)(bit_buffer | shifted);
                input_index++;
            }
            uint code = (uint)(bit_buffer >> 13) & 7;
            if (code >= 4) output_bits += 3;
            bit_buffer = (ushort)(bit_buffer << 3);
            phase = (phase + 1) & 7;
        }
        output_size = output_bits >> 3;
    }
    return output_size;
}
