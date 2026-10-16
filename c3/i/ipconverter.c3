module ipconverter;

const usz MAX_PARSEABLE_INPUT_LENGTH = 38;
const usz MAX_OUTPUT_LENGTH = 35;

fn long ipconverter(long* input, usz length, char* output, usz capacity) @export("ipconverter") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long mode = input[0], payload_length_value = input[1];
    if ((mode != 0 && mode != 1) || payload_length_value < 0 || payload_length_value > (long)MAX_OUTPUT_LENGTH) return -1;
    usz payload_length = (usz)payload_length_value;
    if (length != payload_length + 2) return -1;

    long[4] octets = {0, 0, 0, 0};
    usz position = 0;
    if (mode == 0) {
        if (payload_length < 7 || payload_length > 15) return -1;
        for (usz octet = 0; octet < 4; octet++) {
            usz digits = 0;
            long value = 0;
            while (position < payload_length && input[2 + position] != 46) {
                long byte = input[2 + position];
                if (digits == 3 || byte < 48 || byte > 57) return -1;
                value = value * 10 + byte - 48;
                if (value > 255) return -1;
                digits++;
                position++;
            }
            if (digits == 0) return -1;
            octets[octet] = value;
            if (octet < 3) {
                if (position >= payload_length || input[2 + position] != 46) return -1;
                position++;
            } else if (position != payload_length) return -1;
        }
    } else {
        if (payload_length != 35) return -1;
        for (usz octet = 0; octet < 4; octet++) {
            long value = 0;
            for (usz bit = 0; bit < 8; bit++) {
                long byte = input[2 + position++];
                if (byte != 48 && byte != 49) return -1;
                value = value * 2 + byte - 48;
            }
            octets[octet] = value;
            if (octet < 3 && input[2 + position++] != 46) return -1;
        }
        if (position != payload_length) return -1;
    }

    usz output_length = mode == 0 ? 35 : 3;
    if (mode == 1) {
        for (usz i = 0; i < 4; i++) output_length += octets[i] >= 100 ? 2 : octets[i] >= 10 ? 1 : 0;
    }
    if (capacity < output_length || output == null) return -2;

    position = 0;
    for (usz octet = 0; octet < 4; octet++) {
        if (mode == 0) {
            for (long bit = 7; bit >= 0; bit--) output[position++] = (char)(48 + ((octets[octet] >> bit) & 1));
        } else {
            long value = octets[octet];
            if (value >= 100) { output[position++] = (char)(48 + value / 100); value = value % 100; }
            if (value >= 10) { output[position++] = (char)(48 + value / 10); value = value % 10; }
            output[position++] = (char)(48 + value);
        }
        if (octet < 3) output[position++] = '.';
    }
    return (long)position;
}
