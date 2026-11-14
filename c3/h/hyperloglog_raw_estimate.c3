module hyperloglog_raw_estimate;

fn ulong gcd(ulong a, ulong b) {
    while (b != 0) { ulong r = a % b; a = b; b = r; }
    return a;
}

long hyperloglog_raw_estimate(long* input, usz length, char* output, usz capacity)
        @export("hyperloglog_raw_estimate") {
    if (input == null || length < 1 || length > 130) return -1;
    long raw = input[0];
    if (raw < 0 || raw > 128 || length != raw.usz()+1) return -1;
    usz[16] registers = zeroed;
    for (usz i = 0; i < raw.usz(); i += 1) {
        long value = input[i+1];
        if (value < 0 || value > 4294967295) return -1;
        ulong hash = value.ulong(), bucket = hash >> 28;
        ulong suffix = hash & 268435455, mask = (ulong)1 << 27;
        usz rank = 1;
        while (mask != 0 && (suffix & mask) == 0) { rank += 1; mask >>= 1; }
        if (rank > registers[bucket.usz()]) registers[bucket.usz()] = rank;
    }
    ulong sum = 0;
    for (usz i = 0; i < 16; i += 1) sum += (ulong)1 << (29-registers[i]);
    ulong numerator = (ulong)673*256*((ulong)1<<29), denominator = 1000*sum;
    ulong factor = gcd(numerator,denominator);
    numerator /= factor; denominator /= factor;
    if (output == null || capacity < 144) return -2;
    ulong[18] words = zeroed;
    words[0] = numerator; words[1] = denominator;
    for (usz i = 0; i < 16; i += 1) words[i+2] = registers[i].ulong();
    char[144] staged = zeroed;
    for (usz i = 0; i < 18; i += 1) {
        ulong bits = words[i];
        for (usz b = 0; b < 8; b += 1) { staged[8*i+b] = (char)(bits & 255); bits >>= 8; }
    }
    for (usz i = 0; i < 144; i += 1) output[i] = staged[i];
    return 144;
}
