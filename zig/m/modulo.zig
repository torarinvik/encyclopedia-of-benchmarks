/// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
export fn modulo(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const a = values[0];
    const b = values[1];
    if (a < 0 or a > 4_294_967_295 or b < 1 or b > 4_294_967_295) return -1;
    return @rem(a, b);
}
