const std = @import("std");

export fn sparse_supernodal_cholesky(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 56) return -1;
    if (input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const count: usize = @intCast(input[1]);
    const triangle = n * (n + 1) / 2;
    if (length != 3 + count + n + triangle) return -1;

    var boundaries = [_]usize{0} ** 9;
    var masks = [_]usize{0} ** 8;
    var slots = [_][8]usize{[_]usize{36} ** 8} ** 8;
    for (0..count + 1) |i| {
        if (input[2 + i] < 0 or input[2 + i] > @as(i64, @intCast(n))) return -1;
        boundaries[i] = @intCast(input[2 + i]);
        if (i > 0 and boundaries[i] <= boundaries[i - 1]) return -1;
    }
    if (boundaries[0] != 0 or boundaries[count] != n) return -1;
    for (0..n) |row| {
        const mask = input[3 + count + row];
        const limit = @as(usize, 1) << @intCast(row + 1);
        if (mask < 0 or mask >= @as(i64, @intCast(limit))) return -1;
        masks[row] = @intCast(mask);
        if (masks[row] & (@as(usize, 1) << @intCast(row)) == 0) return -1;
    }
    for (0..n) |col| {
        const bit = @as(usize, 1) << @intCast(col);
        for (col + 1..n) |row| {
            if (masks[row] & bit == 0) continue;
            for (row + 1..n) |lower| {
                if (masks[lower] & bit != 0 and masks[lower] & (@as(usize, 1) << @intCast(row)) == 0) return -1;
            }
        }
    }
    for (0..count) |block| {
        const start = boundaries[block];
        const end = boundaries[block + 1];
        for (start..end) |row| {
            for (start..row) |col| {
                if (masks[row] & (@as(usize, 1) << @intCast(col)) == 0) return -1;
            }
        }
        const bits = ((@as(usize, 1) << @intCast(end)) - 1) ^ ((@as(usize, 1) << @intCast(start)) - 1);
        for (end..n) |row| {
            const selected = masks[row] & bits;
            if (selected != 0 and selected != bits) return -1;
        }
    }

    var sparse = [_]f64{0} ** 36;
    var cursor: usize = 3 + count + n;
    var used: usize = 0;
    for (0..n) |row| {
        for (0..row + 1) |col| {
            const value = input[cursor];
            cursor += 1;
            if (value < -1_000_000 or value > 1_000_000) return -1;
            if (masks[row] & (@as(usize, 1) << @intCast(col)) == 0) {
                if (value != 0) return -1;
            } else {
                slots[row][col] = used;
                sparse[used] = @as(f64, @floatFromInt(value)) / 1000.0;
                used += 1;
            }
        }
    }
    for (0..count) |block| {
        const start = boundaries[block];
        const end = boundaries[block + 1];
        for (start..end) |col| {
            const pivot = sparse[slots[col][col]];
            if (!std.math.isFinite(pivot) or pivot <= 0) return -1;
            sparse[slots[col][col]] = @sqrt(pivot);
            for (col + 1..end) |row| sparse[slots[row][col]] /= sparse[slots[col][col]];
            for (col + 1..end) |row| {
                for (col + 1..row + 1) |target| {
                    sparse[slots[row][target]] -= sparse[slots[row][col]] * sparse[slots[target][col]];
                }
            }
        }
        const bit = @as(usize, 1) << @intCast(start);
        for (end..n) |row| {
            if (masks[row] & bit == 0) continue;
            for (start..end) |col| {
                var value = sparse[slots[row][col]];
                for (start..col) |k| value -= sparse[slots[row][k]] * sparse[slots[col][k]];
                sparse[slots[row][col]] = value / sparse[slots[col][col]];
            }
        }
        for (end..n) |row| {
            if (masks[row] & bit == 0) continue;
            for (end..row + 1) |target| {
                if (masks[target] & bit == 0) continue;
                for (start..end) |k| {
                    sparse[slots[row][target]] -= sparse[slots[row][k]] * sparse[slots[target][k]];
                }
            }
        }
    }
    const required = triangle * 8;
    if (output == null or capacity < required) return -2;
    var offset: usize = 0;
    for (0..n) |row| {
        for (0..row + 1) |col| {
            const value: f64 = if (slots[row][col] == 36) 0 else sparse[slots[row][col]];
            const bits: u64 = @bitCast(value);
            for (0..8) |byte| {
                output[offset] = @truncate(bits >> @intCast(8 * byte));
                offset += 1;
            }
        }
    }
    return @intCast(required);
}
