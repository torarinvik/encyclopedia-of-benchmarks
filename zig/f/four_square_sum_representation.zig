fn floorSqrt(value: i64) i64 {
    var root: i64 = 0;
    while ((root + 1) * (root + 1) <= value) : (root += 1) {}
    return root;
}

export fn four_square_sum_representation(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const n = input[0];
    if (n < 0 or n > 1024) return -1;

    var a = floorSqrt(n);
    while (a >= 0) : (a -= 1) {
        const remainder_a = n - a * a;
        var b_max = floorSqrt(remainder_a);
        if (b_max > a) b_max = a;
        var b = b_max;
        while (b >= 0) : (b -= 1) {
            const remainder_b = remainder_a - b * b;
            var c_max = floorSqrt(remainder_b);
            if (c_max > b) c_max = b;
            var c = c_max;
            while (c >= 0) : (c -= 1) {
                const remainder_c = remainder_b - c * c;
                const d = floorSqrt(remainder_c);
                if (d <= c and d * d == remainder_c) {
                    return (((a * 33 + b) * 33 + c) * 33 + d);
                }
            }
        }
    }
    return -2;
}
