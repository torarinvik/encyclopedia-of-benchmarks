module walker_vose_alias_sampling;

long walker_vose_alias_sampling(long* input, usz length, char* output, usz capacity)
        @export("walker_vose_alias_sampling") {
    if (input == null || length < 3 || length > 83) return -1;
    long nr = input[0], qr = input[1];
    if (nr < 1 || nr > 16 || qr < 0 || qr > 32) return -1;
    usz n = nr.usz(), q = qr.usz();
    if (length != 2 + n + 2 * q) return -1;
    long total = 0;
    for (usz i = 0; i < n; i += 1) {
        if (input[2+i] < 0 || input[2+i] > 100) return -1;
        total += input[2+i];
    }
    if (total == 0) return -1;
    for (usz i = 0; i < q; i += 1) {
        long col = input[2+n+2*i], ticket = input[3+n+2*i];
        if (col < 0 || col >= nr || ticket < 0 || ticket >= total) return -1;
    }
    if (q == 0) return 0;
    if (output == null || capacity < 8*q) return -2;
    long[16] mass = zeroed, threshold = zeroed;
    usz[16] aliases = zeroed, small = zeroed, large = zeroed;
    usz ns = 0, nl = 0;
    for (usz i = 0; i < n; i += 1) {
        mass[i] = nr*input[2+i]; threshold[i] = total; aliases[i] = i;
        if (mass[i] < total) small[ns++] = i; else large[nl++] = i;
    }
    while (ns > 0 && nl > 0) {
        usz low = small[--ns], high = large[--nl];
        threshold[low] = mass[low]; aliases[low] = high;
        mass[high] -= total-mass[low];
        if (mass[high] < total) small[ns++] = high; else large[nl++] = high;
    }
    char[256] staged = zeroed;
    for (usz i = 0; i < q; i += 1) {
        usz col = input[2+n+2*i].usz();
        ulong bits = (ulong)(input[3+n+2*i] < threshold[col] ? col : aliases[col]);
        for (usz b = 0; b < 8; b += 1) { staged[8*i+b] = (char)(bits & 255); bits >>= 8; }
    }
    for (usz i = 0; i < 8*q; i += 1) output[i] = staged[i];
    return (8*q).long();
}
