/// Compute T(n) = n(n+1)/2 without an overflowing intermediate product.
export fn triangular_number(input: i64) i64 {
    if (input < 0 or input > 4_294_967_295) return -1;
    const left: i64 = if (@mod(input, 2) == 0) input / 2 else input;
    const right: i64 = if (@mod(input, 2) == 0) input + 1 else (input + 1) / 2;
    return left * right;
}
