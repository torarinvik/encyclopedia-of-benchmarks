module cramers_rule_2x2;

const long LIMIT = 1000000;

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long cramers_rule_2x2(long* v, usz length, char* output, usz capacity) @export("cramers_rule_2x2") {
    if (v == null || length != 6) return -1;
    for (usz i = 0; i < 6; i++) if (v[i] < -LIMIT || v[i] > LIMIT) return -1;
    long a1=v[0], b1=v[1], c1=v[2], a2=v[3], b2=v[4], c2=v[5];
    long d=a1*b2-a2*b1, dx=c1*b2-c2*b1, dy=a1*c2-a2*c1;
    if (d == 0) return -1;
    if (output == null || capacity < 16) return -2;
    write_f64_le((double)dx / (double)d, output, 0);
    write_f64_le((double)dy / (double)d, output, 8);
    return 2;
}
