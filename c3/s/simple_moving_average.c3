module simple_moving_average;
const usz MAX_ITEMS = 256;
const ulong QUIET_NAN_BITS = 0x7ff8000000000000;
fn void put_u64_le(ulong bits, char* output, usz offset) {
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn long simple_moving_average(long* input, usz length, char* output, usz capacity) @export("simple_moving_average") {
    if (input == null || length < 3) return -1;
    long window_value = input[0], count_value = input[1];
    if (window_value < 1 || window_value > MAX_ITEMS || count_value < 1 || count_value > MAX_ITEMS) return -1;
    usz window = (usz)window_value, count = (usz)count_value;
    if (length != count + 2) return -1;
    for (usz i = 0; i < count; i++) if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) return -1;
    if (capacity < count * 8 || output == null) return -2;
    for (usz i = 0; i < count; i++) {
        if (i + 1 < window) put_u64_le(QUIET_NAN_BITS, output, i * 8);
        else {
            long sum = 0;
            for (usz j = i + 1 - window; j <= i; j++) sum += input[2 + j];
            double average = (double)sum / (double)window;
            ulong bits = @bitcast(ulong, average);
            put_u64_le(bits, output, i * 8);
        }
    }
    return (long)(count * 8);
}
