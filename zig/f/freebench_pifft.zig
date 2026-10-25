const FFT_SIZE: usize = 8;
const BASE: i64 = 1000;
const SCALE: i64 = 1_000_000;

fn fftTransform(real: *[FFT_SIZE]f64, imag: *[FFT_SIZE]f64, inverse: bool) void {
    var j: usize = 0;
    for (1..FFT_SIZE) |i| {
        var bit: usize = FFT_SIZE >> 1;
        while ((j & bit) != 0) {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if (i < j) {
            const temp_real = real.*[i];
            real.*[i] = real.*[j];
            real.*[j] = temp_real;
            const temp_imag = imag.*[i];
            imag.*[i] = imag.*[j];
            imag.*[j] = temp_imag;
        }
    }
    var length: usize = 2;
    while (length <= FFT_SIZE) : (length <<= 1) {
        var root_real: f64 = 0.0;
        var root_imag: f64 = 0.0;
        if (length == 2) {
            root_real = -1.0;
        } else if (length == 4) {
            root_imag = if (inverse) 1.0 else -1.0;
        } else {
            root_real = 0.7071067811865476;
            root_imag = if (inverse) 0.7071067811865476 else -0.7071067811865476;
        }
        const half = length / 2;
        var start: usize = 0;
        while (start < FFT_SIZE) : (start += length) {
            var twiddle_real: f64 = 1.0;
            var twiddle_imag: f64 = 0.0;
            for (0..half) |offset| {
                const even = start + offset;
                const odd = even + half;
                const odd_real = real.*[odd] * twiddle_real - imag.*[odd] * twiddle_imag;
                const odd_imag = real.*[odd] * twiddle_imag + imag.*[odd] * twiddle_real;
                const even_real = real.*[even];
                const even_imag = imag.*[even];
                real.*[even] = even_real + odd_real;
                imag.*[even] = even_imag + odd_imag;
                real.*[odd] = even_real - odd_real;
                imag.*[odd] = even_imag - odd_imag;
                const next_real = twiddle_real * root_real - twiddle_imag * root_imag;
                twiddle_imag = twiddle_real * root_imag + twiddle_imag * root_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) {
        for (0..FFT_SIZE) |i| {
            real.*[i] /= @as(f64, @floatFromInt(FFT_SIZE));
            imag.*[i] /= @as(f64, @floatFromInt(FFT_SIZE));
        }
    }
}

fn fftMultiplyFixed(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    var sign: i64 = 1;
    if (left < 0) { sign = -sign; left = -left; }
    if (right < 0) { sign = -sign; right = -right; }
    var left_real: [FFT_SIZE]f64 = @splat(0.0);
    var left_imag: [FFT_SIZE]f64 = @splat(0.0);
    var right_real: [FFT_SIZE]f64 = @splat(0.0);
    var right_imag: [FFT_SIZE]f64 = @splat(0.0);
    for (0..3) |i| {
        left_real[i] = @floatFromInt(@rem(left, BASE));
        right_real[i] = @floatFromInt(@rem(right, BASE));
        left = @divTrunc(left, BASE);
        right = @divTrunc(right, BASE);
    }
    fftTransform(&left_real, &left_imag, false);
    fftTransform(&right_real, &right_imag, false);
    for (0..FFT_SIZE) |i| {
        const product_real = left_real[i] * right_real[i] - left_imag[i] * right_imag[i];
        const product_imag = left_real[i] * right_imag[i] + left_imag[i] * right_real[i];
        left_real[i] = product_real;
        left_imag[i] = product_imag;
    }
    fftTransform(&left_real, &left_imag, true);
    var product: i64 = 0;
    var place: i64 = 1;
    for (0..5) |i| {
        const coefficient: i64 = @intFromFloat(left_real[i] + 0.5);
        product += coefficient * place;
        place *= BASE;
    }
    const rounded = @divTrunc(product + SCALE / 2, SCALE);
    return sign * rounded;
}

fn fixedSqrt(value: i64) i64 {
    if (value <= 0) return 0;
    const radicand = value * SCALE;
    var root = radicand;
    while (true) {
        const next = @divTrunc(root + @divTrunc(radicand, root), 2);
        if (next >= root) break;
        root = next;
    }
    const lower_error = radicand - root * root;
    const upper_error = (root + 1) * (root + 1) - radicand;
    return if (upper_error < lower_error) root + 1 else root;
}

fn fixedHalf(value: i64) i64 {
    return if (value < 0) -@divTrunc(-value, 2) else @divTrunc(value, 2);
}

fn fixedDivide(numerator: i64, denominator: i64) i64 {
    if (denominator <= 0) return 0;
    const scaled = numerator * SCALE;
    if (scaled < 0) return -@divTrunc(-scaled + @divTrunc(denominator, 2), denominator);
    return @divTrunc(scaled + @divTrunc(denominator, 2), denominator);
}

export fn freebench_pifft(nfft: i64) i64 {
    if (nfft != @as(i64, @intCast(FFT_SIZE))) return -1;
    var c = fixedSqrt(125_000);
    var a = SCALE + 3 * c;
    var b = fixedSqrt(a);
    var e = b - 625_000;
    b *= 2;
    c = e - c;
    a += e;
    var npow: i64 = 4;
    for (0..8) |_| {
        npow *= 2;
        e = fixedHalf(a + b);
        b = fixedSqrt(fftMultiplyFixed(a, b));
        e -= b;
        b *= 2;
        c -= e;
        a = e + b;
        if (e >= -1 and e <= 1) break;
    }
    e = fixedHalf(e);
    e = fftMultiplyFixed(e, e);
    a += b;
    const numerator = fftMultiplyFixed(a, a) - e - fixedHalf(e);
    const denominator = fftMultiplyFixed(a, c) - e;
    var pi = fixedDivide(numerator, denominator);
    pi = @divTrunc(pi + @divTrunc(npow, 2), npow);
    return @divTrunc(pi + 500, 1000);
}
