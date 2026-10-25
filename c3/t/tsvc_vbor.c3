module tsvc_vbor;

const MAX_N = 128;

fn long tsvc_vbor(long* values, usz length) @export("tsvc_vbor") {
    if (values == null || length < 7 || length > 1 + 6 * MAX_N) return -1;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 6 * n) return -1;
    for (usz index = 1; index < length; index++) {
        if (values[index] < 0 || values[index] > 2) return -1;
    }

    long checksum = 0;
    for (usz i = 0; i < n; i++) {
        long a = values[1 + i];
        long b = values[1 + n + i];
        long c = values[1 + 2 * n + i];
        long d = values[1 + 3 * n + i];
        long e = values[1 + 4 * n + i];
        long f = values[1 + 5 * n + i];
        long a1 = a*b*c + a*b*d + a*b*e + a*b*f + a*c*d + a*c*e + a*c*f + a*d*e + a*d*f + a*e*f;
        long b1 = b*c*d + b*c*e + b*c*f + b*d*e + b*d*f + b*e*f;
        long c1 = c*d*e + c*d*f + c*e*f;
        long d1 = d*e*f;
        checksum += a1*b1*c1*d1;
    }
    return checksum;
}
