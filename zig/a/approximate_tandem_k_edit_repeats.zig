const MaxText: usize = 12;
const MaxInput: usize = 14;
const MaxOutput: usize = 1592;

fn editDistance(input: []const i64, a: usize, aLength: usize, b: usize, bLength: usize) usize {
    var row: [MaxText + 1]usize = undefined;
    for (0..bLength + 1) |j| row[j] = j;
    for (1..aLength + 1) |i| {
        var diagonal = row[0];
        row[0] = i;
        for (1..bLength + 1) |j| {
            const above = row[j];
            const deletion = above + 1;
            const insertion = row[j - 1] + 1;
            const substitution = diagonal + @as(usize, @intFromBool(input[2 + a + i - 1] != input[2 + b + j - 1]));
            row[j] = @min(@min(deletion, insertion), substitution);
            diagonal = above;
        }
    }
    return row[bLength];
}

fn minimumEditCost(input: []const i64, start: usize, factorLength: usize) usize {
    var best: usize = 1000;
    var pieceStarts: [MaxText]usize = undefined;
    var pieceLengths: [MaxText]usize = undefined;
    var prefix: usize = 0;
    while (prefix <= factorLength) : (prefix += 1) {
        var suffix: usize = 0;
        while (prefix + suffix <= factorLength) : (suffix += 1) {
            const middle = factorLength - prefix - suffix;
            if (middle < 2) continue;
            const endMask = @as(usize, 1) << @intCast(middle - 1);
            var mask: usize = 1;
            while (mask < endMask) : (mask += 1) {
                var segments: usize = 0;
                var previous: usize = 0;
                var cut: usize = 1;
                while (cut < middle) : (cut += 1) {
                    if ((mask & (@as(usize, 1) << @intCast(cut - 1))) != 0) {
                        pieceStarts[segments] = start + prefix + previous;
                        pieceLengths[segments] = cut - previous;
                        segments += 1;
                        previous = cut;
                    }
                }
                pieceStarts[segments] = start + prefix + previous;
                pieceLengths[segments] = middle - previous;
                segments += 1;
                var left: usize = 1000;
                var fragment: usize = 0;
                while (fragment <= pieceLengths[0]) : (fragment += 1) {
                    left = @min(left, editDistance(input, start, prefix,
                        pieceStarts[0] + pieceLengths[0] - fragment, fragment));
                }
                const last = segments - 1;
                var right: usize = 1000;
                fragment = 0;
                while (fragment <= pieceLengths[last]) : (fragment += 1) {
                    right = @min(right, editDistance(input, pieceStarts[last], fragment,
                        start + factorLength - suffix, suffix));
                }
                var internal: usize = 0;
                for (0..last) |i| {
                    internal += editDistance(input, pieceStarts[i], pieceLengths[i],
                        pieceStarts[i + 1], pieceLengths[i + 1]);
                }
                best = @min(best, left + internal + right);
            }
        }
    }
    return best;
}

fn countRecords(input: []const i64, n: usize, budget: usize) usize {
    var count: usize = 0;
    for (0..n) |start| {
        var factorLength: usize = 2;
        while (factorLength <= n - start) : (factorLength += 1) {
            if (minimumEditCost(input, start, factorLength) <= budget) count += 1;
        }
    }
    return count;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn approximate_tandem_k_edit_repeats(input_opt: ?[*]const i64, length: usize,
                                            output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    const budget0 = input[1];
    if (n0 < 2 or n0 > @as(i64, @intCast(MaxText)) or budget0 < 0 or budget0 > 4
        or length != @as(usize, @intCast(n0)) + 2) return -1;
    const n: usize = @intCast(n0);
    const budget: usize = @intCast(budget0);
    const words = input[0 .. n + 2];
    for (words[2..]) |symbol| if (symbol < 0 or symbol > 3) return -1;
    const count = countRecords(words, n, budget);
    const bytes = 8 * (1 + 3 * count);
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(count));
    var record: usize = 0;
    for (0..n) |start| {
        var factorLength: usize = 2;
        while (factorLength <= n - start) : (factorLength += 1) {
            const cost = minimumEditCost(words, start, factorLength);
            if (cost <= budget) {
                const offset = 8 * (1 + 3 * record);
                storeI64Le(output, offset, @intCast(start));
                storeI64Le(output, offset + 8, @intCast(factorLength));
                storeI64Le(output, offset + 16, @intCast(cost));
                record += 1;
            }
        }
    }
    return @intCast(bytes);
}
