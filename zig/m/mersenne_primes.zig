export fn mersenne_primes(n: i64) i64 {
    if (n < 2 or n > 31) return -1;
    if (n == 2) return 1;
    const modulus = (@as(i64, 1) << @intCast(n)) - 1;
    var residue: i64 = 4;
    for (0..@intCast(n - 2)) |_| {
        residue = @rem(residue * residue - 2, modulus);
    }
    return if (residue == 0) 1 else 0;
}
