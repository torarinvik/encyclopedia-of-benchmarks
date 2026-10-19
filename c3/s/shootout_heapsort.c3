module shootout_heapsort;

const usz MAX_LENGTH = 8192;
const usz OUTPUT_BYTES = 9;
const long MODULUS = 139968;
const long MULTIPLIER = 3877;
const long INCREMENT = 29573;

fn void source_heapsort(usz n, double* values) {
    usz i, j;
    usz ir = n;
    usz l = (n >> 1) + 1;
    double rra;
    while (true) {
        if (l > 1) {
            l -= 1;
            rra = values[l];
        } else {
            rra = values[ir];
            values[ir] = values[1];
            ir -= 1;
            if (ir == 1) {
                values[1] = rra;
                return;
            }
        }
        i = l;
        j = l << 1;
        while (j <= ir) {
            if (j < ir && values[j] < values[j + 1]) j += 1;
            if (rra < values[j]) {
                values[i] = values[j];
                i = j;
                j += i;
            } else {
                j = ir + 1;
            }
        }
        values[i] = rra;
    }
}

fn void write_fixed_six(double value, char* output) {
    ulong millionths = (ulong)(value * 1000000.0 + 0.5);
    ulong whole = millionths / 1000000;
    ulong fraction = millionths % 1000000;
    output[0] = (char)('0' + whole);
    output[1] = '.';
    ulong divisor = 100000;
    for (usz index = 2; index < 8; index += 1) {
        output[index] = (char)('0' + (fraction / divisor) % 10);
        divisor /= 10;
    }
    output[8] = '\n';
}

fn long shootout_heapsort(long length, char* output, usz output_capacity)
    @export("shootout_heapsort") {
    if (length < 2 || length > (long)MAX_LENGTH) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    double[MAX_LENGTH + 1] values;
    long state = 42;
    for (usz index = 1; index <= (usz)length; index += 1) {
        state = (state * MULTIPLIER + INCREMENT) % MODULUS;
        values[index] = 1.0 * (double)state / (double)MODULUS;
    }
    source_heapsort((usz)length, &values[0]);
    write_fixed_six(values[(usz)length], output);
    return (long)OUTPUT_BYTES;
}
