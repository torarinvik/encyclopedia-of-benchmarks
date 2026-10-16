module gauss_seidel_method;

extern fn double round(double value);
const usz MAX_N = 8;
const long MAX_ENTRY = 1000000000;

fn void put_f64_le(double value, char* output, usz offset) {
    char* bytes = (char*)&value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = bytes[byte];
}

fn long gauss_seidel_method(long* input, usz length, char* output, usz capacity) @export("gauss_seidel_method") {
    if (input == null || length < 1 || input[0] < 1 || input[0] > 8) return -1;
    usz n = (usz)input[0];
    if (length != 1 + n*n + n) return -1;
    usz rhs = 1 + n*n;
    for (usz k = 1; k < length; k++) if (input[k] < -MAX_ENTRY || input[k] > MAX_ENTRY) return -1;
    for (usz row = 0; row < n; row++) {
        long diagonal = input[1 + row*n + row];
        if (diagonal <= 0) return -1;
        long off_sum = 0;
        for (usz col = 0; col < n; col++) {
            long value = input[1 + row*n + col];
            if (value != input[1 + col*n + row]) return -1;
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        if (diagonal <= off_sum) return -1;
    }
    if (output == null || capacity < n*8) return -2;
    double[64] a;
    double[8] b;
    double[8] x;
    double[8] old;
    for (usz i = 0; i < 64; i++) a[i] = 0.0;
    for (usz i = 0; i < 8; i++) { b[i] = 0.0; x[i] = 0.0; old[i] = 0.0; }
    for (usz i = 0; i < n*n; i++) a[i] = (double)input[i+1] / 1000000.0;
    for (usz i = 0; i < n; i++) b[i] = (double)input[rhs+i] / 1000000.0;
    for (int iteration = 0; iteration < 1000; iteration++) {
        for (usz i = 0; i < n; i++) old[i] = x[i];
        for (usz i = 0; i < n; i++) {
            double before = 0.0;
            double after = 0.0;
            for (usz j = 0; j < i; j++) before += a[i*n+j] * x[j];
            for (usz j = i+1; j < n; j++) after += a[i*n+j] * old[j];
            x[i] = (b[i] - before - after) / a[i*n+i];
        }
        bool done = true;
        for (usz i = 0; i < n; i++) if (x[i] - old[i] >= 1.0e-10 || old[i] - x[i] >= 1.0e-10) done = false;
        if (done) break;
    }
    for (usz i = 0; i < n; i++) put_f64_le(round(x[i]*1.0e10)/1.0e10, output, i*8);
    return (long)(n*8);
}
