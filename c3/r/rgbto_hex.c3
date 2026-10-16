module rgbto_hex;

const usz RGB_CHANNEL_COUNT = 3;
const usz RGB_HEX_OUTPUT_LENGTH = 7;

fn char hex_digit(long value) {
    return (char)(if value < 10 then 48 + value else 87 + value);
}

fn long rgbto_hex(long* input, usz length, char* output, usz capacity) @export("rgbto_hex") {
    if (length != RGB_CHANNEL_COUNT || input == null) return -1;
    for (usz i = 0; i < RGB_CHANNEL_COUNT; i++) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }
    if (capacity < RGB_HEX_OUTPUT_LENGTH || output == null) return -2;
    output[0] = '#';
    for (usz i = 0; i < RGB_CHANNEL_COUNT; i++) {
        output[1 + 2 * i] = hex_digit(input[i] >> 4);
        output[2 + 2 * i] = hex_digit(input[i] & 15);
    }
    return (long)RGB_HEX_OUTPUT_LENGTH;
}
