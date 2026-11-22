module string_left_rotation;

const usz MAX_STRING_LENGTH = 256;
const usz MAX_PARSEABLE_INPUT_LENGTH = 259;

fn long string_left_rotation(long* input, usz length, char* output, usz capacity) @export("string_left_rotation") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_length = input[0];
    long raw_rotation = input[1];
    if (raw_length < 0 || raw_length > 256 || raw_rotation < 0 || raw_rotation > raw_length || length != (usz)raw_length + 2) return -1;
    usz text_length = (usz)raw_length;
    usz rotation = (usz)raw_rotation;
    ushort[256] units = {};
    for (usz i = 0; i < text_length; i += 1) {
        if (input[i + 2] < 0 || input[i + 2] > 65535) return -1;
        units[i] = (ushort)input[i + 2];
    }
    usz required = text_length * 2;
    if (required == 0) return 0;
    if (output == null || capacity < required) return -2;
    for (usz source = rotation; source < text_length; ++source) {
        ushort value = units[source];
        output[2 * (source - rotation)] = (char)(value & 255);
        output[2 * (source - rotation) + 1] = (char)(value >> 8);
    }
    usz suffix_bytes = 2 * (text_length - rotation);
    for (usz source = 0; source < rotation; ++source) {
        ushort value = units[source];
        output[suffix_bytes + 2 * source] = (char)(value & 255);
        output[suffix_bytes + 2 * source + 1] = (char)(value >> 8);
    }
    return (long)required;
}
