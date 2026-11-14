module hyperloglog_corrected_estimate;
extern fn double log(double value);
extern fn double log1p(double value);

long hyperloglog_corrected_estimate(long* input, usz length, char* output, usz capacity)
        @export("hyperloglog_corrected_estimate") {
    if (input == null || length < 1 || length > 130) return -1;
    long raw = input[0];
    if (raw < 0 || raw > 128 || length != raw.usz()+1) return -1;
    usz[16] registers = zeroed;
    for (usz i = 0; i < raw.usz(); i += 1) {
        long value = input[i+1];
        if (value < 0 || value > 4294967295) return -1;
        ulong hash = value.ulong(), suffix = hash & 268435455;
        usz bucket = (hash >> 28).usz(), rank = 1;
        ulong mask = (ulong)1 << 27;
        while (mask != 0 && (suffix & mask) == 0) { rank += 1; mask >>= 1; }
        if (rank > registers[bucket]) registers[bucket] = rank;
    }
    ulong sum = 0;
    usz zeros = 0;
    for (usz i = 0; i < 16; i += 1) {
        sum += (ulong)1 << (29-registers[i]);
        if (registers[i] == 0) zeros += 1;
    }
    double estimate = 673.0*256.0*536870912.0/(1000.0*sum.double());
    double universe = 4294967296.0;
    if (estimate <= 40.0 && zeros != 0) estimate = 16.0*log(16.0/zeros.double());
    else if (estimate > universe/30.0) {
        if (estimate >= universe) return -3;
        estimate = -universe*log1p(-estimate/universe);
    }
    if (output == null || capacity < 8) return -2;
    ulong bits = @bitcast(ulong,estimate);
    char[8] staged = zeroed;
    for (usz b = 0; b < 8; b += 1) { staged[b] = (char)(bits & 255); bits >>= 8; }
    for (usz b = 0; b < 8; b += 1) output[b] = staged[b];
    return 8;
}
