module misc_lowercase;

const usz MAX_CHARACTERS = 31;
const usz MAX_OUTPUT_BYTES = 63;

fn long misc_lowercase(long* input, usz input_length, char* output, usz output_capacity)
    @export("misc_lowercase") {
    if (input == null || input_length < 1 || input_length > MAX_CHARACTERS + 2) return -1;
    long raw_length = input[0];
    if (raw_length < 0 || raw_length > (long)MAX_CHARACTERS || input_length != (usz)raw_length + 1) return -1;
    usz length = (usz)raw_length;
    ushort[31] lowered;
    char[63] staged;
    char ascii_flag = 1;
    for (usz index = 0; index < length; index++) {
        long raw = input[index + 1];
        if (raw < 0 || raw > 65535) return -1;
        ushort value = (ushort)raw;
        if (value > 0x7f) ascii_flag = 0;
        lowered[index] = value | ((value >= 'A' && value <= 'Z') << 5);
    }
    usz required = 1 + 2 * length;
    if (output == null || output_capacity < required) return -2;
    staged[0] = ascii_flag;
    for (usz index = 0; index < length; index++) {
        staged[1 + 2 * index] = (char)(lowered[index] & 0xff);
        staged[2 + 2 * index] = (char)(lowered[index] >> 8);
    }
    for (usz index = 0; index < required; index++) output[index] = staged[index];
    return (long)required;
}
