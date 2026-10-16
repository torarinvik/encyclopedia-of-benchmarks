module remove_duplicate_from_string;

const usz MAX_TEXT_LENGTH = 512;
const usz MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2;

fn long remove_duplicate_from_string(long* input, usz length, u8* output,
                                     usz output_capacity)
    @export("remove_duplicate_from_string")
{
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > (long)MAX_TEXT_LENGTH ||
        length != 1 + (usz)text_length_value) { return -1; }
    usz text_length = (usz)text_length_value;
    u8[MAX_TEXT_LENGTH] result = zeroed;
    u8[128] seen = zeroed;
    usz result_length = 0;
    for (usz index = 0; index < text_length; index++) {
        long value = input[index + 1];
        if (value < 0 || value > 127) { return -1; }
        usz byte = (usz)value;
        if (seen[byte] == 0) {
            seen[byte] = 1;
            result[result_length++] = (u8)value;
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == null)) { return -2; }
    for (usz index = 0; index < result_length; index++) { output[index] = result[index]; }
    return (long)result_length;
}
