const MAX_LENGTH: usize = 128;

fn gcdPositive(a: i64, b: i64) i64 {
    var left = a;
    var right = b;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn push(value: i64, items: [*]i64, aggregates: [*]i64, length: *usize) void {
    items[length.*] = value;
    aggregates[length.*] = if (length.* == 0) value else gcdPositive(aggregates[length.* - 1], value);
    length.* += 1;
}

export fn shortest_coprime_segment(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |i| if (input[i] < 1 or input[i] > 1000) return -1;
    var front = [_]i64{0} ** MAX_LENGTH;
    var front_gcd = [_]i64{0} ** MAX_LENGTH;
    var back = [_]i64{0} ** MAX_LENGTH;
    var back_gcd = [_]i64{0} ** MAX_LENGTH;
    var front_length: usize = 0;
    var back_length: usize = 0;
    var left: usize = 0;
    var best_start: usize = 0;
    var best_length = length + 1;
    for (0..length) |right| {
        push(input[right], &back, &back_gcd, &back_length);
        var window_gcd = gcdPositive(
            if (front_length > 0) front_gcd[front_length - 1] else 0,
            if (back_length > 0) back_gcd[back_length - 1] else 0);
        while (window_gcd == 1) {
            const current_length = right - left + 1;
            if (current_length < best_length) { best_length = current_length; best_start = left; }
            if (front_length == 0) {
                while (back_length > 0) {
                    back_length -= 1;
                    push(back[back_length], &front, &front_gcd, &front_length);
                }
            }
            front_length -= 1;
            left += 1;
            window_gcd = gcdPositive(
                if (front_length > 0) front_gcd[front_length - 1] else 0,
                if (back_length > 0) back_gcd[back_length - 1] else 0);
        }
    }
    if (best_length > length) return 0;
    const byte_count = best_length * 8;
    if (output_capacity < byte_count) return -2;
    for (0..best_length) |i| {
        const bits: u64 = @intCast(input[best_start + i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(byte_count);
}
