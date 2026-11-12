const max_n: usize = 64;
const max_input_values: usize = 1 + max_n * max_n;

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn matrix_det_mod_2(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > 64) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var rows: [max_n]u64 = @splat(0);
    for (0..n) |row| {
        for (0..n) |column| {
            const bit = input[1 + row * n + column];
            if (bit != 0 and bit != 1) return -1;
            rows[row] |= @as(u64, @intCast(bit)) << @intCast(column);
        }
    }

    var pivot_row: usize = 0;
    for (0..n) |column| {
        var pivot = pivot_row;
        while (pivot < n and ((rows[pivot] >> @intCast(column)) & 1) == 0) : (pivot += 1) {}
        if (pivot == n) continue;
        const temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = temporary;
        for (pivot_row + 1..n) |row| {
            if (((rows[row] >> @intCast(column)) & 1) != 0) rows[row] ^= rows[pivot_row];
        }
        pivot_row += 1;
    }

    if (output_opt == null or capacity < 8) return -2;
    storeI64Le(output_opt.?, if (pivot_row == n) 1 else 0);
    return 8;
}
