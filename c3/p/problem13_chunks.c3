module problem13_chunks;

const long MAX_INPUT_BYTES = 5000;
const usz MAX_INPUT_VALUES = 5001;
const usz CHUNK_WIDTH = 50;

fn long problem13_chunks(long* values, usz length, char* output, usz capacity) @export("problem13_chunks") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 || values[0] > MAX_INPUT_BYTES || (usz)values[0] != length - 1) return -1;

    usz byte_length = (usz)values[0];
    for (usz index = 0; index < byte_length; index++) {
        if (values[index + 1] < '0' || values[index + 1] > '9') return -1;
    }

    usz width = byte_length < CHUNK_WIDTH ? byte_length : CHUNK_WIDTH;
    u8[52] reversed;
    usz reversed_length = 0;
    long carry = 0;
    for (usz remaining = width; remaining > 0; remaining--) {
        usz position = remaining - 1;
        long column = carry;
        for (usz start = 0; start < byte_length; start += CHUNK_WIDTH) {
            usz chunk_length = byte_length - start < CHUNK_WIDTH
                ? byte_length - start : CHUNK_WIDTH;
            if (position < chunk_length) column += values[1 + start + position] - '0';
        }
        reversed[reversed_length] = (u8)(column % 10);
        reversed_length++;
        carry = column / 10;
    }
    while (carry > 0) {
        reversed[reversed_length] = (u8)(carry % 10);
        reversed_length++;
        carry /= 10;
    }

    usz output_length = reversed_length < 10 ? reversed_length : 10;
    if (output == null || capacity < output_length) return -2;
    for (usz index = 0; index < output_length; index++) {
        output[index] = (char)('0' + reversed[reversed_length - 1 - index]);
    }
    return (long)output_length;
}
