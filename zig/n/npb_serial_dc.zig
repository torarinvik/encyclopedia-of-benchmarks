/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: packed input and ordered scalar checksum
 * replace generated files and the original memory management harness.
 */
const MAX_DIMS: usize = 5;
const MAX_ROWS: usize = 16;

export fn npb_serial_dc(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 4 or length > 98 or values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMS)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_ROWS))) return -1;
    const dimensions: usize = @intCast(values[0]);
    const rows: usize = @intCast(values[1]);
    if (length != 2 + rows * (dimensions + 1)) return -1;
    var attributes: [MAX_ROWS][MAX_DIMS]i64 = @splat(@splat(0));
    var measures: [MAX_ROWS]i64 = @splat(0);
    var offset: usize = 2;
    for (0..rows) |row| {
        for (0..dimensions) |dimension| {
            const value = values[offset];
            offset += 1;
            if (value < 0 or value > 7) return -1;
            attributes[row][dimension] = value;
        }
        measures[row] = values[offset];
        offset += 1;
        if (measures[row] < 0 or measures[row] > 1000) return -1;
    }

    var checksum: i64 = 0;
    for (1..(1 << dimensions)) |mask| {
        var keys: [MAX_ROWS][MAX_DIMS]i64 = @splat(@splat(0));
        var sums: [MAX_ROWS]i64 = @splat(0);
        var group_count: usize = 0;
        for (0..rows) |row| {
            var group: usize = 0;
            while (group < group_count) {
                var equal = true;
                for (0..dimensions) |dimension| {
                    if ((mask & (@as(usize, 1) << dimension)) != 0 and keys[group][dimension] != attributes[row][dimension]) equal = false;
                }
                if (equal) break;
                group += 1;
            }
            if (group == group_count) {
                for (0..dimensions) |dimension| {
                    if ((mask & (@as(usize, 1) << dimension)) != 0) keys[group][dimension] = attributes[row][dimension];
                }
                sums[group] = measures[row];
                group_count += 1;
            } else sums[group] += measures[row];
        }
        for (1..group_count) |index| {
            var position = index;
            while (position > 0) {
                var comparison: i32 = 0;
                for (0..dimensions) |dimension| {
                    if ((mask & (@as(usize, 1) << dimension)) == 0) continue;
                    if (keys[position][dimension] < keys[position - 1][dimension]) { comparison = -1; break; }
                    if (keys[position][dimension] > keys[position - 1][dimension]) { comparison = 1; break; }
                }
                if (comparison >= 0) break;
                const temporary = keys[position];
                keys[position] = keys[position - 1];
                keys[position - 1] = temporary;
                const temporary_sum = sums[position];
                sums[position] = sums[position - 1];
                sums[position - 1] = temporary_sum;
                position -= 1;
            }
        }
        const view: i64 = @intCast(mask);
        checksum += view * 1009 + @as(i64, @intCast(group_count)) * 9176;
        for (0..group_count) |group| {
            checksum += (view + 1) * @as(i64, @intCast(group + 1)) * (sums[group] + 13);
            for (0..dimensions) |dimension| {
                if ((mask & (@as(usize, 1) << dimension)) != 0) {
                    checksum += @as(i64, @intCast(dimension + 1)) * (keys[group][dimension] + 1) *
                                @as(i64, @intCast(group + 3)) * (view + 5);
                }
            }
        }
    }
    return checksum;
}
