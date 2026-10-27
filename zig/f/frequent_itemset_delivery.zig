const MAX_INPUT: usize = 69;
const MAX_OUTPUT: usize = 200;

fn putU64(output: [*c]u8, word: usize, value: u64) void {
    for (0..8) |byte| output[word * 8 + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn frequent_itemset_delivery(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 6 or length > MAX_INPUT) return -1;
    const n0 = input[0]; const rows0 = input[1]; const minimum = input[2];
    const tail = input[3]; const prefix0 = input[4];
    if (n0 < 1 or n0 > 8 or rows0 < 1 or rows0 > 64 or minimum < 1 or minimum > rows0 or length != 5 + @as(usize, @intCast(rows0))) return -1;
    if (tail < -1 or tail >= n0 or prefix0 < 0) return -1;
    const n: usize = @intCast(n0); const row_count: usize = @intCast(rows0);
    const limit = @as(u64, 1) << @as(u6, @intCast(n));
    const prefix: u64 = @intCast(prefix0);
    if (prefix >= limit or (tail == -1 and prefix != 0) or
        (tail >= 0 and (((prefix >> @as(u6, @intCast(tail))) & 1) == 0 or (prefix >> @as(u6, @intCast(tail + 1))) != 0))) return -1;
    var occurrences = [_]u64{0} ** 8;
    var supports = [_]u64{0} ** 8;
    for (0..row_count) |row| {
        const row0 = input[5 + row];
        if (row0 < 0 or @as(u64, @intCast(row0)) >= limit) return -1;
        const mask: u64 = @intCast(row0);
        if ((mask & prefix) != prefix) continue;
        var item: usize = @intCast(tail + 1);
        while (item < n) : (item += 1) {
            if ((mask & (@as(u64, 1) << @as(u6, @intCast(item)))) != 0) {
                occurrences[item] |= @as(u64, 1) << @as(u6, @intCast(row));
                supports[item] += 1;
            }
        }
    }
    var words = [_]u64{0} ** 25;
    var records: usize = 0;
    var item: usize = @intCast(tail + 1);
    while (item < n) : (item += 1) {
        if (supports[item] < @as(u64, @intCast(minimum))) continue;
        const at = 1 + 3 * records; records += 1;
        words[at] = item; words[at + 1] = occurrences[item]; words[at + 2] = supports[item];
    }
    words[0] = records;
    const word_count = 1 + 3 * records; const bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    for (0..word_count) |word| putU64(output, word, words[word]);
    return @intCast(bytes);
}
