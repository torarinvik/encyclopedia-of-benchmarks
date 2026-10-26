module tsvc_s423_antidependence_offset64;
fn long tsvc_s423_antidependence_offset64(long* input, usz length)
    @export("tsvc_s423_antidependence_offset64") {
    const usz min_n = 65; const usz max_n = 128;
    if (input == null || length < 130 || length > 193) return -1;
    if (input[0] < (long)min_n || input[0] > (long)max_n) return -1;
    usz n = (usz)input[0];
    if (length != n + 65) return -1;
    long[128] a; long[192] x;
    for (usz i = 0; i < 192; i++) x[i] = 0;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1+i];
        if (a[i] < 0 || a[i] > 2) return -1;
    }
    for (usz i = 0; i < 64; i++) {
        x[i] = input[1+n+i];
        if (x[i] < 0 || x[i] > 2) return -1;
    }
    for (usz i = 64; i < n+64; i++) x[i] = 1;
    for (usz i = 0; i < n-1; i++) x[i+1] = x[i+64] + a[i];
    long sum = 0;
    for (usz i = 0; i < n; i++) sum += x[i];
    return sum;
}
