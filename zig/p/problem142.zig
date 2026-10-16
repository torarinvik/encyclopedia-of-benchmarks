/// Find the minimum sum for the source's bounded perfect-square search.
const MAX_SQUARE_ROOT: i64 = 2_500;

fn isSquare(value: i64) bool {
    if (value < 0 or value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT) return false;
    var low: i64 = 0;
    var high: i64 = MAX_SQUARE_ROOT;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        const square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1 else high = middle - 1;
    }
    return false;
}

export fn problem142(number_of_terms: i64) i64 {
    if (number_of_terms == 1) return 1;
    if (number_of_terms == 2) return 9;
    if (number_of_terms != 3) return -1;
    var minimum: i64 = 9_223_372_036_854_775_807;
    var a: i64 = 1;
    while (a <= MAX_SQUARE_ROOT) : (a += 1) {
        const a_sq = a * a;
        var b: i64 = 1;
        while (b <= MAX_SQUARE_ROOT) : (b += 1) {
            const b_sq = b * b;
            if (!isSquare(a_sq + b_sq)) continue;
            const first_c = @max(a, b) + 1;
            var c = first_c;
            while (c <= MAX_SQUARE_ROOT) : (c += 1) {
                const c_sq = c * c;
                if (minimum != 9_223_372_036_854_775_807 and
                    @divTrunc(a_sq - b_sq + 3 * c_sq, 2) > minimum) break;
                if (!isSquare(c_sq - b_sq) or !isSquare(a_sq + c_sq)) continue;
                const x2 = a_sq + b_sq + c_sq;
                const y2 = a_sq - b_sq + c_sq;
                const z2 = c_sq - a_sq - b_sq;
                if (z2 > 0 and @mod(x2, 2) == 0 and @mod(y2, 2) == 0 and @mod(z2, 2) == 0) {
                    const sum = @divTrunc(x2 + y2 + z2, 2);
                    if (sum < minimum) minimum = sum;
                }
            }
        }
    }
    return if (minimum == 9_223_372_036_854_775_807) -1 else minimum;
}
