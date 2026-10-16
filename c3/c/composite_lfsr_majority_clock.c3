module composite_lfsr_majority_clock;

fn void write_i64_le(char* output, usz offset, long value) {
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((value >> (8 * byte)) & 255);
}

fn long composite_lfsr_majority_clock(long* input, usz length, char* output,
                                      usz output_capacity) @export("composite_lfsr_majority_clock") {
    if (input == null || length != 3) return -1;
    if (input[0] < 0 || input[0] > 524287 || input[1] < 0 || input[1] > 4194303 || input[2] < 0 || input[2] > 8388607) return -1;
    if (output == null || output_capacity < 32) return -2;
    long s1 = input[0];
    long s2 = input[1];
    long s3 = input[2];
    long c1 = (s1 >> 8) & 1;
    long c2 = (s2 >> 10) & 1;
    long c3 = (s3 >> 10) & 1;
    long majority = c1 + c2 + c3 >= 2 ? 1 : 0;
    long emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1;
    if (c1 == majority) s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1);
    if (c2 == majority) s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ^ (s2 >> 21)) & 1);
    if (c3 == majority) s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1);
    write_i64_le(output, 0, emitted); write_i64_le(output, 8, s1);
    write_i64_le(output, 16, s2); write_i64_le(output, 24, s3);
    return 32;
}
