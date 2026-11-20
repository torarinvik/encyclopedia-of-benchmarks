module reservoir_sampling_algorithm_x;

fn long falling(long top, usz k) {
    long product = 1;
    for (usz i = 0; i < k; i++) product *= top - (long)i;
    return product;
}

fn long gcd_i64(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a;
}

fn long reservoir_sampling_algorithm_x(long* input, usz length, char* output, usz capacity) @export("reservoir_sampling_algorithm_x") {
    if (input == null || length < 3 || length > 49 || input[0] < 1 || input[0] > 16) return -1;
    usz n = (usz)input[0];
    if (input[1] < 1 || input[1] > 8) return -1;
    usz k = (usz)input[1];
    if ((k & (k-1)) != 0 || k > n || length != 2+n+2*(n-k)) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (usz i = 2+n; i < length; i++) if (input[i] < 0 || input[i] > 4294967295) return -1;
    if (output == null || capacity < 8*k) return -2;
    long[8] sample = {};
    for (usz i = 0; i < k; i++) sample[i] = input[2+i];
    usz processed = k, attempt = 0;
    while (processed < n) {
        long draw = input[2+n+2*attempt], slot_draw = input[2+n+2*attempt+1];
        attempt++;
        long numerator = falling((long)processed, k), denominator = falling((long)processed+1, k);
        long divisor = gcd_i64(numerator, denominator);
        numerator /= divisor; denominator /= divisor;
        usz max_skip = n-processed-1, selected = 0;
        bool found = false;
        for (usz skip = 0; skip <= max_skip; skip++) {
            if (numerator*4294967297 <= (draw+1)*denominator) { selected = skip; found = true; break; }
            if (skip < max_skip) {
                long top = (long)(processed+skip+1);
                numerator *= top+1-(long)k; denominator *= top+1;
                divisor = gcd_i64(numerator, denominator);
                numerator /= divisor; denominator /= divisor;
            }
        }
        if (!found) break;
        sample[(usz)(slot_draw % (long)k)] = input[2+processed+selected];
        processed += selected+1;
    }
    for (usz i = 0; i < k; i++) {
        ulong bits = (ulong)sample[i];
        for (usz j = 0; j < 8; j++) { output[8*i+j] = (char)(bits & 255); bits >>= 8; }
    }
    return (long)(8*k);
}
