const MAX_COORDINATE: i64 = 100000;
const MAX_RADIUS: i64 = 100000;

fn countTangents(x1: i64, y1: i64, r1: i64, x2: i64, y2: i64, r2: i64) i64 {
    const dx = x2 - x1;
    const dy = y2 - y1;
    const distance_squared = dx * dx + dy * dy;
    const signs = [_]i64{-1, 1};
    var candidates: i64 = 0;
    for (signs) |first_sign| {
        for (signs) |second_sign| {
            const difference = second_sign * r2 - first_sign * r1;
            if (distance_squared >= difference * difference) candidates += 1;
        }
    }
    if (r1 == 0 and r2 == 0) return 1;
    if (r1 == 0 or r2 == 0) {
        const radius = r1 + r2;
        if (distance_squared == radius * radius) return 1;
        return @divTrunc(candidates, 2);
    }
    const radius_sum = r1 + r2;
    const radius_difference = r1 - r2;
    if (distance_squared == radius_sum * radius_sum or distance_squared == radius_difference * radius_difference) candidates -= 1;
    return candidates;
}

export fn common_tangents_two_circles(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 6) return -1;
    const input = input_opt.?;
    const x1 = input[0];
    const y1 = input[1];
    const r1 = input[2];
    const x2 = input[3];
    const y2 = input[4];
    const r2 = input[5];
    if (x1 < -MAX_COORDINATE or x1 > MAX_COORDINATE or
        y1 < -MAX_COORDINATE or y1 > MAX_COORDINATE or
        x2 < -MAX_COORDINATE or x2 > MAX_COORDINATE or
        y2 < -MAX_COORDINATE or y2 > MAX_COORDINATE or
        r1 < 0 or r1 > MAX_RADIUS or r2 < 0 or r2 > MAX_RADIUS or
        (x1 == x2 and y1 == y2)) return -1;
    return countTangents(x1, y1, r1, x2, y2, r2);
}
