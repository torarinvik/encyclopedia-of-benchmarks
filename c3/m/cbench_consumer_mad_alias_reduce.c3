module cbench_consumer_mad_alias_reduce;

const long[8] CS = {0x0db84a81, 0x0e1b9d7f, 0x0f31adcf, 0x0fbba815, 0x0feda417, 0x0ffc8fc8, 0x0fff964c, 0x0ffff8d3};
const long[8] CA = {-0x083b5fe7, -0x078c36d2, -0x05039814, -0x02e91dd1, -0x0183603a, -0x00a7cb87, -0x003a2847, -0x000f27b4};

fn long floor_div(long value, long divisor) {
    quotient := value / divisor;
    if value % divisor < 0 return quotient - 1;
    return quotient;
}

fn long mad_mul(long left, long right) {
    return floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536);
}

fn void put_i32_le(uchar* output, usz offset, long value) {
    bits := u32(value);
    output[offset] = uchar(bits & 255);
    output[offset + 1] = uchar((bits >> 8) & 255);
    output[offset + 2] = uchar((bits >> 16) & 255);
    output[offset + 3] = uchar((bits >> 24) & 255);
}

fn long cbench_consumer_mad_alias_reduce(long* input, usz length, uchar* output, usz capacity)
    @export("cbench_consumer_mad_alias_reduce") {
    if input == null || length < 1 || length > 65 return -1;
    if input[0] < 1 || input[0] > 4 return -1;
    boundaries := (usz)input[0];
    if length != 1 + 16 * boundaries return -1;
    for i: usz = 1; i < length; i++ {
        if input[i] < -100000000 || input[i] > 100000000 return -1;
    }
    output_size := 64 * boundaries;
    long[64] staged;
    for boundary: usz = 0; boundary < boundaries; boundary++ {
        base := 1 + 16 * boundary;
        for i: usz = 0; i < 8; i++ {
            a, b := input[base + 2 * i], input[base + 2 * i + 1];
            staged[16 * boundary + 2 * i] = mad_mul(a, CS[i]) + mad_mul(-b, CA[i]);
            staged[16 * boundary + 2 * i + 1] = mad_mul(b, CS[i]) + mad_mul(a, CA[i]);
        }
    }
    if output == null || capacity < output_size return -2;
    for i: usz = 0; i < 16 * boundaries; i++ put_i32_le(output, 4 * i, staged[i]);
    return (long)output_size;
}
