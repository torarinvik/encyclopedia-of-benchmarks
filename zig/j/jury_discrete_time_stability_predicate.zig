const MAX_PARSEABLE_LENGTH: usize = 7;

pub export fn jury_discrete_time_stability_predicate(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = values.?;
    const degree_i64 = input[0];
    if (degree_i64 < 1 or degree_i64 > 4 or length != @as(usize, @intCast(degree_i64)) + 2) return -1;
    const degree: usize = @intCast(degree_i64);

    var coefficients = [_]i64{0} ** 5;
    for (0..degree + 1) |index| {
        const value = input[index + 1];
        if (value < -9 or value > 9 or (index == 0 and value == 0)) return -1;
        coefficients[index] = value;
    }
    if (coefficients[0] < 0) {
        for (0..degree + 1) |index| coefficients[index] = -coefficients[index];
    }

    var at_one: i64 = 0;
    var at_minus_one: i64 = 0;
    for (0..degree + 1) |index| {
        at_one += coefficients[index];
        if ((degree - index) % 2 == 0) at_minus_one += coefficients[index]
        else at_minus_one -= coefficients[index];
    }
    if (at_one <= 0 or ((degree % 2 == 0 and at_minus_one <= 0) or
        (degree % 2 != 0 and at_minus_one >= 0))) return 0;

    var row = coefficients;
    var reduced = [_]i64{0} ** 5;
    var current_degree = degree;
    while (current_degree >= 1) : (current_degree -= 1) {
        const trailing = row[current_degree];
        const trailing_magnitude = if (trailing < 0) -trailing else trailing;
        if (row[0] <= trailing_magnitude) return 0;
        if (current_degree == 1) break;
        for (0..current_degree) |index| {
            reduced[index] = row[0] * row[index] - trailing * row[current_degree - index];
        }
        for (0..current_degree) |index| row[index] = reduced[index];
    }
    return 1;
}
