/// Iterative factorial for the shared signed 64-bit benchmark contract.
export fn factorial(n: i64) i64 {
    if (n < 0 or n > 20) return -1;

    var product: i64 = 1;
    var factor: i64 = 2;
    while (factor <= n) : (factor += 1) {
        product *= factor;
    }
    return product;
}
