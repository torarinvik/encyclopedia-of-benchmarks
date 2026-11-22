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
    if (text_length == 0) return 0;
    ushort[256] units = {};
    ulong observed_bits = 0;
    for (usz i = 0; i < text_length; i += 1) {
        ulong value = (ulong)input[i + 2];
        observed_bits |= value;
        units[i] = (ushort)value;
    }
    if (observed_bits > 65535) return -1;
    usz required = text_length * 2;
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
