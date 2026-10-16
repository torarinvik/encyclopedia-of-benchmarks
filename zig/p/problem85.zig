/// Search triangular-number products for the rectangle count nearest the target.
const MAX_TARGET: i64 = 2_000_000_000;

fn triangle(side: i64) i64 {
    return side * (side + 1) / 2;
}

fn absoluteDifference(left: i64, right: i64) i64 {
    const difference = left - right;
    return if (difference < 0) -difference else difference;
}

export fn problem85(target: i64) i64 {
    if (target < 0 or target > MAX_TARGET) return -1;
    const bound: i64 = @intFromFloat(@ceil(@sqrt(@as(f64, @floatFromInt(target * 2))) * 1.1));
    var best_product: i64 = 0;
    var area: i64 = 0;
    var triangle_a: i64 = 0;
    var a: i64 = 1;
    while (a < bound) : (a += 1) {
        triangle_a += a;
        const estimate = (-1.0 + @sqrt(1.0 + 8.0 * @as(f64, @floatFromInt(target)) /
            @as(f64, @floatFromInt(triangle_a)))) / 2.0;
        const b_floor: i64 = @intFromFloat(@floor(estimate));
        const b_ceil: i64 = @intFromFloat(@ceil(estimate));
        const first_product = triangle_a * triangle(b_floor);
        const second_product = triangle_a * triangle(b_ceil);
        if (absoluteDifference(target, first_product) < absoluteDifference(target, best_product)) {
            best_product = first_product;
            area = a * b_floor;
        }
        if (absoluteDifference(target, second_product) < absoluteDifference(target, best_product)) {
            best_product = second_product;
            area = a * b_ceil;
        }
    }
    return area;
}
