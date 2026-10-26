const max_k: usize = 8;
const max_items: usize = 64;
const max_input: usize = 66;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn misra_gries_summaries(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const k64 = input[0];
    const count64 = input[1];
    if (k64 < 1 or k64 > 8 or count64 < 0 or count64 > 64 or
        length != 2 + @as(usize, @intCast(count64))) return -1;
    const k: usize = @intCast(k64);
    const count: usize = @intCast(count64);
    var items: [max_k]i64 = [_]i64{-1} ** max_k;
    var counts: [max_k]i64 = [_]i64{0} ** max_k;
    for (0..count) |index| {
        const item = input[index + 2];
        if (item < 0 or item > 15) return -1;
        var slot: usize = 0;
        while (slot < k and items[slot] != item) : (slot += 1) {}
        if (slot < k) { counts[slot] += 1; continue; }
        slot = 0;
        while (slot < k and counts[slot] != 0) : (slot += 1) {}
        if (slot < k) { items[slot] = item; counts[slot] = 1; continue; }
        for (0..k) |decrement_slot| {
            counts[decrement_slot] -= 1;
            if (counts[decrement_slot] == 0) items[decrement_slot] = -1;
        }
    }
    var used: usize = 0;
    for (0..k) |slot| { if (counts[slot] > 0) used += 1; }
    const output_bytes = 8 * (1 + 2 * used);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var ordered_items: [max_k]i64 = [_]i64{0} ** max_k;
    var ordered_counts: [max_k]i64 = [_]i64{0} ** max_k;
    var at: usize = 0;
    for (0..k) |slot| {
        if (counts[slot] <= 0) continue;
        var position = at;
        while (position > 0 and ordered_items[position - 1] > items[slot]) : (position -= 1) {
            ordered_items[position] = ordered_items[position - 1];
            ordered_counts[position] = ordered_counts[position - 1];
        }
        ordered_items[position] = items[slot];
        ordered_counts[position] = counts[slot];
        at += 1;
    }
    storeI64LE(output, 0, @intCast(used));
    for (0..used) |index| {
        storeI64LE(output, 8 * (1 + 2 * index), ordered_items[index]);
        storeI64LE(output, 8 * (2 + 2 * index), ordered_counts[index]);
    }
    return @intCast(output_bytes);
}
