module base85;

const usz MAX_INPUT_VALUES = 66;
const long MAX_U32 = 4294967295;

fn long decode_group(long* values, usz start, usz count) {
    long value = 0;
    for (usz index = 0; index < 5; index++) {
        long digit = 84;
        if (index < count) {
            long byte = values[start + index];
            if (byte < 33 || byte > 117) return -1;
            digit = byte - 33;
        }
        value = value * 85 + digit;
    }
    return value > MAX_U32 ? -1 : value;
}

fn long base85(long* values, usz length, char* output, usz output_capacity)
        @export("base85") {
    if (values == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long mode = values[0];
    usz payload_length = length - 1;
    usz output_length = 0;
    if (mode == 0) {
        for (usz index = 1; index < length; index++)
            if (values[index] < 0 || values[index] > 255) return -1;
        usz remainder = payload_length % 4;
        output_length = (payload_length / 4) * 5 + (remainder == 0 ? 0 : remainder + 1);
    } else if (mode == 1) {
        if (payload_length % 5 == 1) return -1;
        for (usz offset = 0; offset < payload_length;) {
            usz count = payload_length - offset < 5 ? payload_length - offset : 5;
            if (decode_group(values, offset + 1, count) < 0) return -1;
            output_length += count == 5 ? 4 : count - 1;
            offset += count;
        }
    } else {
        return -1;
    }
    if (output_capacity < output_length || (output_length != 0 && output == null)) return -2;

    usz written = 0;
    if (mode == 0) {
        for (usz offset = 0; offset < payload_length; offset += 4) {
            usz count = payload_length - offset < 4 ? payload_length - offset : 4;
            ulong value = 0;
            for (usz byte = 0; byte < 4; byte++) {
                value <<= 8;
                if (byte < count) value |= (ulong)values[offset + byte + 1];
            }
            ulong place = 52200625;
            for (usz digit = 0; digit < 5; digit++) {
                char encoded = (char)(value / place + 33);
                value %= place;
                if (count == 4 || digit < count + 1) output[written++] = encoded;
                if (digit == 0) place = 614125;
                else if (digit == 1) place = 7225;
                else if (digit == 2) place = 85;
                else place = 1;
            }
        }
    } else {
        for (usz offset = 0; offset < payload_length;) {
            usz count = payload_length - offset < 5 ? payload_length - offset : 5;
            ulong value = (ulong)decode_group(values, offset + 1, count);
            usz byte_count = count == 5 ? 4 : count - 1;
            for (usz byte = 0; byte < byte_count; byte++)
                output[written++] = (char)((value >> (24 - 8 * byte)) & 255);
            offset += count;
        }
    }
    return (long)written;
}
