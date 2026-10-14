/// Iterative double factorial for the signed 64-bit benchmark contract.
export fn double_factorial(n: i64) i64 {
    if (n < 0 or n > 33) return -1;
    var product: i64 = 1;
    var factor = n;
    while (factor > 1) : (factor -= 2) {
        product *= factor;
    }
    return product;
}
