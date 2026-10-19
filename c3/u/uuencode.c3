module uuencode;

const usz MAX_INPUT_BYTES = 4096;
const usz MAX_OUTPUT_BYTES = 5675;

fn long symbol(long value) { return 32 + (value & 63); }

fn long uuencode(long* input, usz length, char* output, usz capacity) @export("uuencode") {
    if (input == null || length > MAX_INPUT_BYTES) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    usz needed = 22 + 4 * ((length + 2) / 3) + 2 * ((length + 44) / 45) + 5;
    if (output == null || capacity < needed) return -2;

    usz written = 0;
    output[written++] = (char)98; output[written++] = (char)101;
    output[written++] = (char)103; output[written++] = (char)105;
    output[written++] = (char)110; output[written++] = (char)32;
    output[written++] = (char)54; output[written++] = (char)52;
    output[written++] = (char)48; output[written++] = (char)32;
    output[written++] = (char)117; output[written++] = (char)117;
    output[written++] = (char)101; output[written++] = (char)110;
    output[written++] = (char)99; output[written++] = (char)111;
    output[written++] = (char)100; output[written++] = (char)101;
    output[written++] = (char)46; output[written++] = (char)99;
    output[written++] = (char)32; output[written++] = (char)10;

    usz start = 0;
    while (start < length) {
        usz line_len = length - start;
        if (line_len > 45) line_len = 45;
        usz stop = start + line_len;
        output[written++] = (char)symbol((long)line_len);
        usz index = start;
        while (index < stop) {
            long a = input[index];
            bool has_b = index + 1 < stop;
            bool has_c = index + 2 < stop;
            long b = has_b ? input[index + 1] : 0;
            long c = has_c ? input[index + 2] : 0;
            output[written++] = (char)symbol(a >> 2);
            output[written++] = (char)symbol((a << 4) | (b >> 4));
            output[written++] = has_b ? (char)symbol((b << 2) | (c >> 6)) : (char)61;
            output[written++] = has_c ? (char)symbol(c) : (char)61;
            index += 3;
        }
        output[written++] = (char)10;
        start = stop;
    }
    output[written++] = (char)32; output[written++] = (char)10;
    output[written++] = (char)101; output[written++] = (char)110; output[written++] = (char)100;
    return (long)written;
}
