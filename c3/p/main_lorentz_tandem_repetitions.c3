module main_lorentz_tandem_repetitions;

const usz N = 24, MAX_REPETITIONS = N * N / 4, INPUT_MAX = N + 1, Z_MAX = 2 * N + 1;

fn usz ml_min(usz a, usz b) { return a < b ? a : b; }
fn usz ml_max(usz a, usz b) { return a > b ? a : b; }

fn void ml_z_values(long* text, usz length, usz* z) {
    for (usz i = 0; i < length; i += 1) z[i] = 0;
    usz left = 0, right = 0;
    bool has_box = false;
    for (usz i = 1; i < length; i += 1) {
        if (has_box && i <= right) {
            usz remaining = right - i + 1;
            z[i] = z[i-left] < remaining ? z[i-left] : remaining;
        }
        while (i + z[i] < length && text[z[i]] == text[i+z[i]]) z[i] += 1;
        if (!has_box || i + z[i] - 1 > right) {
            left = i; right = i + z[i] - 1; has_box = true;
        }
    }
}

fn usz ml_z_at(usz* z, usz length, usz index) { return index < length ? z[index] : 0; }

fn void ml_divide(long[N]* symbols, usz offset, usz length, bool* marked) {
    if (length <= 1) return;
    usz left_size = length / 2, right_size = length - left_size, middle = offset + left_size;
    long[Z_MAX] buffer = zeroed;
    usz[Z_MAX] z = zeroed;
    usz[N] before = zeroed, after = zeroed;
    ml_divide(symbols, offset, left_size, marked);
    ml_divide(symbols, middle, right_size, marked);

    for (usz i = 0; i < left_size; i += 1) buffer[i] = symbols[middle-1-i];
    ml_z_values(&buffer[0], left_size, &z[0]);
    for (usz center = 0; center < left_size; center += 1)
        before[center] = ml_z_at(&z[0], left_size, left_size-center);

    usz used = 0;
    for (usz i = 0; i < right_size; i += 1) buffer[used++] = symbols[middle+i];
    buffer[used++] = -1;
    for (usz i = 0; i < left_size; i += 1) buffer[used++] = symbols[offset+i];
    ml_z_values(&buffer[0], used, &z[0]);
    for (usz center = 0; center < left_size; center += 1)
        after[center] = ml_z_at(&z[0], used, right_size+1+center);

    for (usz i = 0; i < left_size; i += 1) buffer[i] = symbols[middle-1-i];
    used = left_size; buffer[used++] = -1;
    for (usz i = 0; i < right_size; i += 1) buffer[used++] = symbols[offset+length-1-i];
    ml_z_values(&buffer[0], used, &z[0]);
    for (usz d = 0; d < right_size; d += 1)
        before[left_size+d] = ml_z_at(&z[0], used, left_size+1+right_size-1-d);

    for (usz i = 0; i < right_size; i += 1) buffer[i] = symbols[middle+i];
    ml_z_values(&buffer[0], right_size, &z[0]);
    for (usz d = 0; d < right_size; d += 1)
        after[left_size+d] = ml_z_at(&z[0], right_size, d+1);

    for (usz center = 0; center < length; center += 1) {
        bool left_biased = center < left_size;
        usz half = left_biased ? left_size-center : center-left_size+1;
        if (before[center] + after[center] < half) continue;
        usz low = ml_max(1, half > after[center] ? half-after[center] : 0);
        usz high = ml_min(half, before[center]);
        for (usz first_half = low; first_half <= high; first_half += 1) {
            if (left_biased && first_half == half) continue;
            usz start = left_biased ? center-first_half : center-half-first_half+1;
            marked[(offset+start)*(N+1)+half] = true;
        }
    }
}

fn void ml_store(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) output[offset+i] = (uint8)((bits >> (8*i)) & 255);
}

fn long main_lorentz_tandem_repetitions(long* input, usz length,
    uint8* output, usz capacity) @export("main_lorentz_tandem_repetitions") {
    if (input == null || length < 1 || length > INPUT_MAX) return -1;
    long nr = input[0];
    if (nr < 0 || nr > (long)N || length != (usz)nr+1) return -1;
    usz n = (usz)nr;
    long[N] symbols = zeroed;
    for (usz i = 0; i < n; i += 1) {
        symbols[i] = input[i+1];
        if (symbols[i] < 0 || symbols[i] > 255) return -1;
    }
    bool[N*(N+1)] marked = zeroed;
    ml_divide(&symbols, 0, n, &marked[0]);
    long[MAX_REPETITIONS] codes = zeroed;
    usz count = 0;
    for (usz start = 0; start < n; start += 1)
        for (usz half = 1; half <= n/2; half += 1)
            if (start+2*half <= n && marked[start*(N+1)+half]) codes[count++] = (long)(start*32+half);
    usz required = 8*(count+1);
    if (output == null || capacity < required) return -2;
    ml_store(output, 0, (long)count);
    for (usz i = 0; i < count; i += 1) ml_store(output, 8*(i+1), codes[i]);
    return (long)required;
}
