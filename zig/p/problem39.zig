fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 1415;
    while (high - low > 1) {
        const middle = (low + high) / 2;
        if (middle * middle <= value) low = middle else high = middle;
    }
    return low;
}

pub export fn problem39(limit: i64) i64 {
    if (limit < 12 or limit > 1000) return -1;
    var counts: [1001]i64 = @splat(0);
    var first_order: [1001]i64 = @splat(0);
    var next_order: i64 = 1;
    var base: i64 = 1;
    while (base <= limit) : (base += 1) {
        var perpendicular = base;
        while (perpendicular <= limit) : (perpendicular += 1) {
            const square_sum = base * base + perpendicular * perpendicular;
            const hypotenuse = integerSqrt(square_sum);
            if (hypotenuse * hypotenuse != square_sum) continue;
            const perimeter = base + perpendicular + hypotenuse;
            if (perimeter > limit) continue;
            const index: usize = @intCast(perimeter);
            if (counts[index] == 0) {
                first_order[index] = next_order;
                next_order += 1;
            }
            counts[index] += 1;
        }
    }
    var best_perimeter: i64 = -1;
    var best_count: i64 = 0;
    var best_order: i64 = 9223372036854775807;
    var perimeter: i64 = 1;
    while (perimeter <= limit) : (perimeter += 1) {
        const index: usize = @intCast(perimeter);
        if (counts[index] > 0 and (counts[index] > best_count or
            (counts[index] == best_count and first_order[index] < best_order))) {
            best_perimeter = perimeter;
            best_count = counts[index];
            best_order = first_order[index];
        }
    }
    return best_perimeter;
}
