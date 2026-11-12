const max_n: usize = 32;
const max_m: usize = 32;
const max_input_values: usize = 2 + max_n * max_m + max_n;

fn storeU64Le(output: [*]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn system_of_linear_equations_mod_2(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 32 or m_value < 1 or m_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n * m + n) return -1;

    var rows: [max_n]u64 = @splat(0);
    var rhs: [max_n]u8 = @splat(0);
    for (0..n) |row| {
        for (0..m) |column| {
            const bit = input[2 + row * m + column];
            if (bit != 0 and bit != 1) return -1;
            rows[row] |= @as(u64, @intCast(bit)) << @intCast(column);
        }
        const bit = input[2 + n * m + row];
        if (bit != 0 and bit != 1) return -1;
        rhs[row] = @intCast(bit);
    }

    var pivot_columns: [max_n]usize = @splat(0);
    var pivot_row: usize = 0;
    for (0..m) |column| {
        var pivot = pivot_row;
        while (pivot < n and ((rows[pivot] >> @intCast(column)) & 1) == 0) : (pivot += 1) {}
        if (pivot == n) continue;
        const row_temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = row_temporary;
        const rhs_temporary = rhs[pivot_row];
        rhs[pivot_row] = rhs[pivot];
        rhs[pivot] = rhs_temporary;
        for (0..n) |row| {
            if (row != pivot_row and ((rows[row] >> @intCast(column)) & 1) != 0) {
                rows[row] ^= rows[pivot_row];
                rhs[row] ^= rhs[pivot_row];
            }
        }
        pivot_columns[pivot_row] = column;
        pivot_row += 1;
    }

    for (pivot_row..n) |row| {
        if (rows[row] == 0 and rhs[row] != 0) {
            if (output_opt == null or capacity < 8) return -2;
            storeU64Le(output_opt.?, 0, 0xffffffffffffffff);
            return 8;
        }
    }

    var is_pivot: [max_m]bool = @splat(false);
    for (0..pivot_row) |row| is_pivot[pivot_columns[row]] = true;
    const nullity = m - pivot_row;
    const output_bytes = 8 * (nullity + 2);
    if (output_opt == null or capacity < output_bytes) return -2;

    var particular: u64 = 0;
    for (0..pivot_row) |row| {
        if (rhs[row] != 0) particular |= @as(u64, 1) << @intCast(pivot_columns[row]);
    }
    const output = output_opt.?;
    storeU64Le(output, 0, @intCast(nullity));
    storeU64Le(output, 8, particular);
    var basis_index: usize = 0;
    for (0..m) |free_column| {
        if (is_pivot[free_column]) continue;
        var basis = @as(u64, 1) << @intCast(free_column);
        for (0..pivot_row) |row| {
            if (((rows[row] >> @intCast(free_column)) & 1) != 0)
                basis |= @as(u64, 1) << @intCast(pivot_columns[row]);
        }
        storeU64Le(output, 16 + 8 * basis_index, basis);
        basis_index += 1;
    }
    return @intCast(output_bytes);
}
