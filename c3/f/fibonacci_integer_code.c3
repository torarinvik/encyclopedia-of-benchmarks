module fibonacci_integer_code;

fn long fibonacci_integer_code(long* input, usz length, uint8* output, usz capacity) @export("fibonacci_integer_code") {
    if (input == null || length < 2 || length > 33) return -1;
    long n0 = input[0];
    if (n0 < 1 || n0 > 32 || length != (usz)(n0 + 1)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 1000000) return -1;
    ulong[30] fib; fib[0] = 1; fib[1] = 2;
    usz fib_count = 2;
    while (fib_count < 30 && fib[fib_count - 1] + fib[fib_count - 2] <= 1000001) {
        fib[fib_count] = fib[fib_count - 1] + fib[fib_count - 2]; fib_count++;
    }
    uint8[960] staged;
    usz out = 0;
    for (usz v = 0; v < n; v++) {
        ulong remaining = (ulong)(input[v + 1] + 1);
        usz top = 0;
        while (top + 1 < fib_count && fib[top + 1] <= remaining) top++;
        uint8[30] bits;
        usz j = top + 1;
        while (j > 0) {
            j--;
            if (fib[j] <= remaining) { bits[j] = 1; remaining -= fib[j]; }
        }
        for (usz i = 0; i <= top; i++) { staged[out] = (uint8)('0' + bits[i]); out++; }
        staged[out] = '1'; out++;
    }
    if (output == null || capacity < out) return -2;
    for (usz i = 0; i < out; i++) output[i] = staged[i];
    return (long)out;
}
