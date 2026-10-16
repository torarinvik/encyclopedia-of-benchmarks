const MAX_N: i64 = 512;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

fn find_bound(values: [*c]const i64, n: usize, key: i64, find_left: bool) i32 {
    var left: usize = 0;
    var right: isize = @as(isize, @intCast(n)) - 1;
    while (@as(isize, @intCast(left)) <= right) {
        const left_signed: isize = @intCast(left);
        const mid: usize = @intCast(left_signed + @divTrunc(right - left_signed, 2));
        if (values[mid] > key) {
            right = @as(isize, @intCast(mid)) - 1;
        } else if (values[mid] < key) {
            left = mid + 1;
        } else if (find_left) {
            if (mid == 0 or values[mid - 1] != key) return @intCast(mid);
            right = @as(isize, @intCast(mid)) - 1;
        } else {
            if (mid == n - 1 or values[mid + 1] != key) return @intCast(mid);
            left = mid + 1;
        }
    }
    return -1;
}

fn put_i32_le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn range_in_sorted_array(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const n_i64 = input[0];
    if (n_i64 < 0 or n_i64 > MAX_N or length != @as(usize, @intCast(n_i64)) + 2) return -1;
    const n: usize = @intCast(n_i64);
    const key = input[n + 1];
    if (key < INT32_MIN_VALUE or key > INT32_MAX_VALUE) return -1;
    for (0..n) |index| {
        const value = input[index + 1];
        if (value < INT32_MIN_VALUE or value > INT32_MAX_VALUE) return -1;
        if (index > 0 and input[index] > value) return -1;
    }
    const first = find_bound(input + 1, n, key, true);
    const last = find_bound(input + 1, n, key, false);
    if (output == null or output_capacity < 8) return -2;
    put_i32_le(output, 0, first);
    put_i32_le(output, 4, last);
    return 8;
}
