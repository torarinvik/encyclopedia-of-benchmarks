module uudecode;

const usz MAX_INPUT_BYTES = 4096;
const usz MAX_OUTPUT_BYTES = 2949;

fn bool scan(long* input, usz length, usz* decoded_length) {
    if (input == null || length > MAX_INPUT_BYTES) return false;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 255) return false;
    if (length < 29) return false;
    if (input[0] != 98 || input[1] != 101 || input[2] != 103 || input[3] != 105 ||
        input[4] != 110 || input[5] != 32 || input[6] != 55 || input[7] != 53 ||
        input[8] != 53 || input[9] != 32 || input[10] != 117 || input[11] != 117 ||
        input[12] != 115 || input[13] != 116 || input[14] != 97 || input[15] != 114 ||
        input[16] != 116 || input[17] != 46 || input[18] != 102 || input[19] != 105 ||
        input[20] != 108 || input[21] != 101 || input[22] != 32 || input[23] != 10) return false;

    usz offset = 24;
    usz total = 0;
    while (offset < length) {
        long marker = input[offset++];
        if (marker == 32) {
            if (offset + 4 != length || input[offset] != 10 || input[offset + 1] != 101 ||
                input[offset + 2] != 110 || input[offset + 3] != 100) return false;
            *decoded_length = total;
            return total <= MAX_OUTPUT_BYTES;
        }
        long count = marker - 32;
        if (count < 1 || count > 45) return false;
        usz encoded = 4 * ((((usz)count) + 2) / 3);
        if (offset + encoded >= length || input[offset + encoded] != 10) return false;
        for (usz i = 0; i < encoded; i++) if (input[offset + i] < 32 || input[offset + i] > 95) return false;
        total += (usz)count;
        if (total > MAX_OUTPUT_BYTES) return false;
        offset += encoded + 1;
    }
    return false;
}

fn long uudecode(long* input, usz length, uchar* output, usz capacity) @export("uudecode") {
    usz decoded_length = 0;
    if (!scan(input, length, &decoded_length)) return -1;
    if (output == null || capacity < decoded_length) return -2;

    usz offset = 24;
    usz written = 0;
    while (true) {
        usz count = (usz)(input[offset++] - 32);
        if (count == 0) break;
        usz encoded = 4 * ((count + 2) / 3);
        usz emitted = 0;
        for (usz group = 0; group < encoded; group += 4) {
            long a = input[offset++] - 32;
            long b = input[offset++] - 32;
            long c = input[offset++] - 32;
            long d = input[offset++] - 32;
            output[written++] = (uchar)((a << 2) | (b >> 4));
            emitted++;
            if (emitted < count) {
                output[written++] = (uchar)((b << 4) | (c >> 2));
                emitted++;
            }
            if (emitted < count) {
                output[written++] = (uchar)((c << 6) | d);
                emitted++;
            }
        }
        offset++;
    }
    return (long)written;
}
