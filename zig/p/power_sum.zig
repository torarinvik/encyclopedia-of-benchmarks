/// Count distinct positive bases whose powers sum to the target.
fn search(target: i64, power: i64, base: i64, current_sum: i64) i64 {
    var term: i64 = 1;
    for (0..@intCast(power)) |_| {
        term *= base;
    }
    const new_sum = current_sum + term;
    if (new_sum == target) return 1;
    if (new_sum > target) return 0;
    return search(target, power, base + 1, new_sum) + search(target, power, base + 1, current_sum);
}

export fn power_sum(input_values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const target = input_values[0];
    const power = input_values[1];
    if (target < 1 or target > 1000 or power < 2 or power > 10) return -1;
    return search(target, power, 1, 0);
}
