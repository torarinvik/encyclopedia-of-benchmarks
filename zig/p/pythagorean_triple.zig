/// Check three signed integers with Java-compatible int-safe bounds.
export fn pythagorean_triple(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    var a = values[0];
    var b = values[1];
    var c = values[2];
    if (a < -32768 or a > 32767 or b < -32768 or b > 32767 or c < -32768 or c > 32767) return -1;
    if (a <= 0 or b <= 0 or c <= 0) return 0;
    if (a > b) { const t = a; a = b; b = t; }
    if (b > c) { const t = b; b = c; c = t; }
    if (a > b) { const t = a; a = b; b = t; }
    return if (a * a + b * b == c * c) 1 else 0;
}
