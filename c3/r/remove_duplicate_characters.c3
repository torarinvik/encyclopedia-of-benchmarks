module remove_duplicate_characters;

const usz MAX_INPUT_LENGTH = 4096;

fn long remove_duplicate_characters(long* values, usz length, char* output, usz output_capacity)
    @export("remove_duplicate_characters") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > (long)MAX_INPUT_LENGTH ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    for (usz index = 0; index < text_length; index++)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    bool[128] seen = zeroed;
    usz output_length = 0;
    for (usz index = 0; index < text_length; index++) {
        usz byte = (usz)values[index + 1];
        if (!seen[byte]) { seen[byte] = true; output_length++; }
    }
    if (output_length > output_capacity || (output_length > 0 && output == null)) return -2;

    for (usz index = 0; index < 128; index++) seen[index] = false;
    usz written = 0;
    for (usz index = 0; index < text_length; index++) {
        usz byte = (usz)values[index + 1];
        if (!seen[byte]) { seen[byte] = true; output[written++] = (char)byte; }
    }
    return (long)written;
}
