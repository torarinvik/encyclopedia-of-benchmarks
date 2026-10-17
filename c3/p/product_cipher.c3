module product_cipher;

const long MAX_TEXT_LENGTH = 256;
const long MAX_COLUMNS = 64;
const usz MAX_INPUT_VALUES = 259;
const usz MAX_OUTPUT_BYTES = 315;

fn long product_cipher(long* input, usz length, uchar* output, usz output_capacity)
    @export("product_cipher") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_COLUMNS ||
        input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return -1;

    usz columns = (usz)input[0];
    usz text_length = (usz)input[1];
    if (length != 2 + text_length) return -1;
    for (usz index = 0; index < text_length; index++) {
        long byte = input[2 + index];
        if (byte < 0 || byte > 127 || byte == 10 || byte == 13) return -1;
    }

    usz padded_length = text_length == 0 ? 0 : ((text_length + columns - 1) / columns) * columns;
    if (padded_length > MAX_OUTPUT_BYTES) return -1;
    if (padded_length == 0) return 0;
    if (output == null || output_capacity < padded_length) return -2;

    uchar[MAX_OUTPUT_BYTES] padded = zeroed;
    for (usz index = 0; index < text_length; index++)
        padded[index] = (uchar)(input[2 + index] + 5);
    for (usz index = text_length; index < padded_length; index++)
        padded[index] = (uchar)'/';
    usz rows = padded_length / columns;
    usz written = 0;
    for (usz column = 0; column < columns; column++) {
        for (usz row = 0; row < rows; row++)
            output[written++] = padded[column + row * columns];
    }
    return (long)written;
}
