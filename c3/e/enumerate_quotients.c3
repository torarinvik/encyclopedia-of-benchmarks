module enumerate_quotients;

fn long enumerate_quotients(long value, char* output, usz output_capacity)
    @export("enumerate_quotients") {
    const long MAX_N = 100000;
    if (value < 1 || value > MAX_N) return -1;
    ulong n = (ulong)value;
    usz count = 0;
    for (ulong left = 1; left <= n;) {
        ulong quotient = n / left;
        count++;
        left = n / quotient + 1;
    }
    usz byte_count = (count + 1) * 8;
    if (output == null || output_capacity < byte_count) return -2;
    ulong count_word = (ulong)count;
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)((count_word >> (byte * 8)) & 255);
    }
    usz index = 0;
    for (ulong left = 1; left <= n;) {
        ulong quotient = n / left;
        for (usz byte = 0; byte < 8; byte++) {
            output[(index + 1) * 8 + byte] = (char)((quotient >> (byte * 8)) & 255);
        }
        index++;
        left = n / quotient + 1;
    }
    return (long)byte_count;
}
