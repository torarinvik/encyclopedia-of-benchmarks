const max_modulus: i64 = 1_000_000_000;

fn reciprocity(numerator: i64, denominator: i64) i64 {
    var a = numerator;
    var n = denominator;
    var sign: i64 = 1;
    while (a != 0) {
        while (@rem(a, 2) == 0) {
            a = @divTrunc(a, 2);
            const residue = @rem(n, 8);
            if (residue == 3 or residue == 5) sign = -sign;
        }
        if (@rem(a, 4) == 3 and @rem(n, 4) == 3) sign = -sign;
        const old_a = a;
        a = n;
        n = old_a;
        a = @rem(a, n);
    }
    return if (n == 1) sign else 0;
}

export fn jacobi_symbol(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const words = input.?;
    const numerator = words[0];
    const denominator = words[1];
    if (denominator < 1 or denominator > max_modulus or @rem(denominator, 2) == 0) return -1;
    if (numerator < 0 or numerator >= denominator) return -1;
    return reciprocity(numerator, denominator) + 1;
}
