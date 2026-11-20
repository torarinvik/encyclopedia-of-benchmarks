const max_n: usize = 16;
const max_nonzer: usize = 4;
const max_support: usize = 5;
const max_triplets: usize = 416;
const max_input: usize = 3 + 2 * max_n * max_nonzer;
const max_value_micro: i64 = 1_000_000;
const max_shift_micro: i64 = 10_000_000;
const scale: f64 = 1_000_000.0;
const rcond: f64 = 0.1;

const Parsed = struct { n: usize, nonzer: usize };

fn valid(v: []const i64) ?Parsed {
    if (v.len < 3 or v.len > max_input or v[0] < 2 or v[0] > @as(i64, @intCast(max_n)) or
        v[1] < 1 or v[1] > @as(i64, @intCast(max_nonzer)) or v[2] < 0 or v[2] > max_shift_micro) return null;
    const n: usize = @intCast(v[0]);
    const nonzer: usize = @intCast(v[1]);
    if (v.len != 3 + 2 * n * nonzer) return null;
    var cursor: usize = 3;
    for (0..n) |_| {
        var seen: u32 = 0;
        for (0..nonzer) |_| {
            const coordinate = v[cursor];
            const value = v[cursor + 1];
            cursor += 2;
            if (coordinate < 0 or coordinate >= @as(i64, @intCast(n)) or value == 0 or
                value < -max_value_micro or value > max_value_micro) return null;
            const bit = @as(u32, 1) << @as(u5, @intCast(coordinate));
            if ((seen & bit) != 0) return null;
            seen |= bit;
        }
    }
    return .{ .n = n, .nonzer = nonzer };
}

fn writeU64(output: []u8, offset: *usize, bits: u64) void {
    for (0..8) |byte| {
        output[offset.*] = @truncate(bits >> @intCast(8 * byte));
        offset.* += 1;
    }
}

fn writeF64(output: []u8, offset: *usize, value: f64) void {
    writeU64(output, offset, @bitCast(value));
}

export fn npb_cg_sparse_outer_product_assembly(input: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > max_input) return -1;
    const v = input.?[0..length];
    const parsed = valid(v) orelse return -1;
    const n = parsed.n;
    const nonzer = parsed.nonzer;
    var raw_rows: [max_triplets]u8 = @splat(0);
    var raw_columns: [max_triplets]u8 = @splat(0);
    var raw_values: [max_triplets]f64 = @splat(0.0);
    var raw_count: usize = 0;
    var cursor: usize = 3;
    for (0..n) |vector| {
        var coordinates: [max_support]u8 = @splat(0);
        var vector_values: [max_support]f64 = @splat(0.0);
        var support_count = nonzer;
        var has_anchor = false;
        for (0..nonzer) |entry| {
            const coordinate: usize = @intCast(v[cursor]);
            coordinates[entry] = @intCast(coordinate);
            vector_values[entry] = @as(f64, @floatFromInt(v[cursor + 1])) / scale;
            cursor += 2;
            if (coordinate == vector) {
                vector_values[entry] = 0.5;
                has_anchor = true;
            }
        }
        if (!has_anchor) {
            coordinates[support_count] = @intCast(vector);
            vector_values[support_count] = 0.5;
            support_count += 1;
        }
        const weight: f64 = if (vector == 0) 1.0 else if (vector + 1 == n) rcond
            else std.math.pow(f64, rcond, @as(f64, @floatFromInt(vector)) / @as(f64, @floatFromInt(n - 1)));
        for (0..support_count) |column_slot| {
            const scaled_column = weight * vector_values[column_slot];
            for (0..support_count) |row_slot| {
                raw_rows[raw_count] = coordinates[row_slot];
                raw_columns[raw_count] = coordinates[column_slot];
                raw_values[raw_count] = vector_values[row_slot] * scaled_column;
                raw_count += 1;
            }
        }
    }
    const diagonal_addend = rcond - @as(f64, @floatFromInt(v[2])) / scale;
    for (0..n) |diagonal| {
        raw_rows[raw_count] = @intCast(diagonal);
        raw_columns[raw_count] = @intCast(diagonal);
        raw_values[raw_count] = diagonal_addend;
        raw_count += 1;
    }

    var column_pointers: [max_n + 1]i64 = @splat(0);
    var row_indices: [max_n * max_n]u8 = @splat(0);
    var matrix_values: [max_n * max_n]f64 = @splat(0.0);
    var nnz: usize = 0;
    for (0..n) |column| {
        column_pointers[column] = @intCast(nnz);
        for (0..n) |row| {
            var sum: f64 = 0.0;
            var touched = false;
            for (0..raw_count) |triple| {
                if (@as(usize, raw_rows[triple]) == row and @as(usize, raw_columns[triple]) == column) {
                    sum += raw_values[triple];
                    touched = true;
                }
            }
            if (touched) {
                row_indices[nnz] = @intCast(row);
                matrix_values[nnz] = sum;
                nnz += 1;
            }
        }
    }
    column_pointers[n] = @intCast(nnz);
    const required = 8 * (2 + (n + 1) + 2 * nnz);
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?[0..required];
    var offset: usize = 0;
    writeF64(output, &offset, @floatFromInt(n));
    writeF64(output, &offset, @floatFromInt(nnz));
    for (column_pointers[0 .. n + 1]) |pointer| writeF64(output, &offset, @floatFromInt(pointer));
    for (row_indices[0..nnz]) |row| writeF64(output, &offset, @floatFromInt(row));
    for (matrix_values[0..nnz]) |value| writeF64(output, &offset, value);
    return @intCast(required);
}
