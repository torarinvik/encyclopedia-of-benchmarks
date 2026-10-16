const modulus: i64 = 10_000_000_000;

pub export fn problem48(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var total: i64 = 0;
    var base: i64 = 1;
    while (base <= 1000) : (base += 1) {
        var term: i64 = 1;
        var exponent: i64 = 0;
        while (exponent < base) : (exponent += 1) {
            term = @mod(term * base, modulus);
        }
        total = @mod(total + term, modulus);
    }
    return total;
}
