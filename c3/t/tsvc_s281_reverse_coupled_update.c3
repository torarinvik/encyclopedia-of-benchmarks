// Clean-room port of TSVC s281; see the package README for provenance and rights.

module tsvc_s281_reverse_coupled_update;

const int MAX_N = 16;
const usz MAX_INPUT_LENGTH = 50;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long tsvc_s281_reverse_coupled_update(long* input, usz length,
        char* output, usz capacity) @export("tsvc_s281_reverse_coupled_update") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > 8) return -1;
    usz n = input[0].usz();
    usz passes = input[1].usz();
    if (length != 2 + 3 * n) return -1;

    double a[MAX_N];
    double b[MAX_N];
    double c[MAX_N];
    for (usz i = 0; i < n; i++) {
        long av = input[2 + i];
        long bv = input[2 + n + i];
        long cv = input[2 + 2 * n + i];
        if (av < -2 || av > 2 || bv < -2 || bv > 2 || cv < -1 || cv > 1) return -1;
        a[i] = (double)av;
        b[i] = (double)bv;
        c[i] = (double)cv;
    }

    usz output_bytes = 16 * n;
    if (output == null || capacity < output_bytes) return -2;
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 0; i < n; i++) {
            double x = a[n - i - 1] + b[i] * c[i];
            a[i] = x - 1.0;
            b[i] = x;
        }
    }
    for (usz i = 0; i < n; i++) {
        store_i64_le((long)a[i], output, 8 * i);
        store_i64_le((long)b[i], output, 8 * (n + i));
    }
    return output_bytes.long();
}
