module shootout_strcat;

const long MAX_APPEND_COUNT = 4096;
const long MAX_TEXT_BYTES = MAX_APPEND_COUNT * 6;

fn long shootout_strcat(long append_count, char* output, usz output_capacity)
    @export("shootout_strcat") {
    if (append_count < 0 || append_count > MAX_APPEND_COUNT) return -1;
    char[MAX_TEXT_BYTES + 1] text;
    usz length = 0;
    usz buffer_capacity = 32;
    const char* suffix = "hello\n";
    for (long append = 0; append < append_count; append++) {
        if (buffer_capacity - length < 7) buffer_capacity *= 2;
        for (usz index = 0; index < 6; index++) text[length + index] = suffix[index];
        length += 6;
        text[length] = 0;
    }
    char[6] staged;
    char[5] reversed;
    usz digit_count = 0;
    usz output_length = 0;
    usz value = length;
    do {
        reversed[digit_count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (digit_count > 0) staged[output_length++] = reversed[--digit_count];
    staged[output_length++] = '\n';
    if (output == null || output_capacity < output_length) return -2;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
