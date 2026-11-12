// Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005.
const MAX_DIMS: usize = 5;
const MAX_ROWS: usize = 16;
const MAX_MASKS: usize = 32;

fn keyEqual(a: [MAX_DIMS]i64, b: [MAX_DIMS]i64, mask: usize, dimensions: usize) bool {
    for (0..dimensions) |dimension| {
        if ((mask & (@as(usize, 1) << dimension)) != 0 and a[dimension] != b[dimension]) return false;
    }
    return true;
}

fn keyLess(a: [MAX_DIMS]i64, b: [MAX_DIMS]i64, mask: usize, dimensions: usize) bool {
    for (0..dimensions) |dimension| {
        if ((mask & (@as(usize, 1) << dimension)) == 0) continue;
        if (a[dimension] < b[dimension]) return true;
        if (a[dimension] > b[dimension]) return false;
    }
    return false;
}

export fn npb_dc_smallest_parent(input: ?[*]const i64, length: usize) i64 {
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

    var keys: [MAX_MASKS][MAX_ROWS][MAX_DIMS]i64 = @splat(@splat(@splat(0)));
    var sums: [MAX_MASKS][MAX_ROWS]i64 = @splat(@splat(0));
    var counts: [MAX_MASKS]usize = @splat(0);
    var parents: [MAX_MASKS]i32 = @splat(-2);
    const full = (@as(usize, 1) << dimensions) - 1;
    parents[full] = -1;
    for (0..rows) |row| {
        var group: usize = 0;
        while (group < counts[full] and !keyEqual(keys[full][group], attributes[row], full, dimensions)) : (group += 1) {}
        if (group == counts[full]) {
            keys[full][group] = attributes[row];
            sums[full][group] = measures[row];
            counts[full] += 1;
        } else sums[full][group] += measures[row];
    }
    for (1..counts[full]) |index| {
        var position = index;
        while (position > 0 and keyLess(keys[full][position], keys[full][position - 1], full, dimensions)) : (position -= 1) {
            const temporary = keys[full][position];
            keys[full][position] = keys[full][position - 1];
            keys[full][position - 1] = temporary;
            const temporary_sum = sums[full][position];
            sums[full][position] = sums[full][position - 1];
            sums[full][position - 1] = temporary_sum;
        }
    }

    var wanted: i32 = @as(i32, @intCast(dimensions)) - 1;
    while (wanted >= 0) : (wanted -= 1) {
        for (0..(full + 1)) |mask| {
            if (@as(i32, @intCast(@popCount(mask))) != wanted) continue;
            var parent: usize = MAX_MASKS;
            var best: usize = MAX_ROWS + 1;
            for (0..dimensions) |dimension| {
                const bit = @as(usize, 1) << dimension;
                if ((mask & bit) != 0) continue;
                const candidate = mask | bit;
                if (parent == MAX_MASKS or counts[candidate] < best) {
                    parent = candidate;
                    best = counts[candidate];
                }
            }
            if (parent == MAX_MASKS) return -1;
            parents[mask] = @intCast(parent);
            for (0..counts[parent]) |parent_group| {
                var group: usize = 0;
                while (group < counts[mask] and !keyEqual(keys[mask][group], keys[parent][parent_group], mask, dimensions)) : (group += 1) {}
                if (group == counts[mask]) {
                    for (0..dimensions) |dimension| {
                        if ((mask & (@as(usize, 1) << dimension)) != 0) keys[mask][group][dimension] = keys[parent][parent_group][dimension];
                    }
                    sums[mask][group] = sums[parent][parent_group];
                    counts[mask] += 1;
                } else sums[mask][group] += sums[parent][parent_group];
            }
            for (1..counts[mask]) |index| {
                var position = index;
                while (position > 0 and keyLess(keys[mask][position], keys[mask][position - 1], mask, dimensions)) : (position -= 1) {
                    const temporary = keys[mask][position];
                    keys[mask][position] = keys[mask][position - 1];
                    keys[mask][position - 1] = temporary;
                    const temporary_sum = sums[mask][position];
                    sums[mask][position] = sums[mask][position - 1];
                    sums[mask][position - 1] = temporary_sum;
                }
            }
        }
    }

    var checksum: i64 = 0;
    for (0..(full + 1)) |mask| {
        const view: i64 = @intCast(mask + 1);
        checksum += view * 1_000_000 + (@as(i64, parents[mask]) + 2) * 10_000 + @as(i64, @intCast(counts[mask])) * 1_000;
        for (0..counts[mask]) |group| {
            const rank: i64 = @intCast(group + 1);
            checksum += rank * (sums[mask][group] + 1);
            for (0..dimensions) |dimension| {
                if ((mask & (@as(usize, 1) << dimension)) != 0) {
                    checksum += rank * @as(i64, @intCast(dimension + 1)) * (keys[mask][group][dimension] + 1);
                }
            }
        }
    }
    return checksum;
}
