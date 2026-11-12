module nim_product_64;

fn ulong nim_product(ulong a, ulong b, int width) {
    if (width == 1) return a & b;
    int half = width / 2;
    ulong mask = (1u64 << half) - 1u64;
    ulong a_low = a & mask;
    ulong a_high = a >> half;
    ulong b_low = b & mask;
    ulong b_high = b >> half;
    ulong low_product = nim_product(a_low, b_low, half);
    ulong high_product = nim_product(a_high, b_high, half);
    ulong cross = nim_product(a_low ^ a_high, b_low ^ b_high, half)
                ^ low_product ^ high_product;
    ulong constant = 1u64 << (half - 1);
    ulong low = low_product ^ nim_product(high_product, constant, half);
    ulong high = cross ^ high_product;
    return low ^ (high << half);
}

fn long nim_product_64(long* input, usz length, uchar* output, usz output_capacity)
    @export("nim_product_64") {
    if (input == null || length != 4) return -1;
    for (usz index = 0; index < 4; index++)
        if (input[index] < 0 || input[index] > 4294967295) return -1;
    if (output == null || output_capacity < 8) return -2;

    ulong a = (ulong)input[0] | ((ulong)input[1] << 32);
    ulong b = (ulong)input[2] | ((ulong)input[3] << 32);
    ulong result = nim_product(a, b, 64);
    for (int index = 0; index < 8; index++)
        output[index] = (uchar)(result >> (8 * index));
    return 8;
}
