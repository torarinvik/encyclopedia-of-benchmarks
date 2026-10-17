module length;

const usz MAX_PAYLOAD_BYTES = 256;
const usz MAX_INPUT_LENGTH = 259;
const usz OUTPUT_BYTES = 16;

fn long utf8_scalar_count(uint8* bytes, usz length) {
    usz index = 0;
    long count = 0;
    while (index < length) {
        uint8 lead = bytes[index];
        if (lead >= 1 && lead <= 0x7f) {
            index++;
        } else if (lead >= 0xc2 && lead <= 0xdf) {
            if (index + 1 >= length || bytes[index + 1] < 0x80 || bytes[index + 1] > 0xbf) return -1;
            index += 2;
        } else if (lead >= 0xe0 && lead <= 0xef) {
            if (index + 2 >= length) return -1;
            uint8 second = bytes[index + 1], third = bytes[index + 2];
            if (second < 0x80 || second > 0xbf || third < 0x80 || third > 0xbf ||
                (lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f)) return -1;
            index += 3;
        } else return -1;
        count++;
    }
    return count;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long length(long* input, usz input_length, char* output, usz output_capacity) @export("length") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_PAYLOAD_BYTES) return -1;
    usz payload_length = (usz)input[0];
    if (input_length != payload_length + 2) return -1;

    uint8[MAX_PAYLOAD_BYTES] payload = {0};
    for (usz index = 0; index <= payload_length; index++) {
        long value = input[index + 1];
        if (value < 0 || value > 255) return -1;
        if (index == payload_length) {
            if (value != 0) return -1;
        } else {
            if (value == 0) return -1;
            payload[index] = (uint8)value;
        }
    }
    long scalar_count = utf8_scalar_count(&payload[0], payload_length);
    if (scalar_count < 0) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    put_i64_le(output, 0, (long)payload_length);
    put_i64_le(output, 8, scalar_count);
    return (long)OUTPUT_BYTES;
}
