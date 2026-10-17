module modulo;

// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
fn long modulo(long* values, usz length) @export("modulo") {
    if (values == null || length != 2) return -1;
    long a = values[0];
    long b = values[1];
    if (a < 0 || a > 4294967295 || b < 1 || b > 4294967295) return -1;
    return a % b;
}
