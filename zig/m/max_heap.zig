const MAX_OPERATIONS: usize = 512;
const MAX_INSERTIONS: usize = 256;
fn storeI64Le(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> (8 * b));
}
export fn max_heap(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length < 1) return -1;
    const input = raw[0..length];
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return -1;
    const operations: usize = @intCast(input[0]);
    if (length != 1 + operations * 2) return -1;
    var inserts: usize = 0;
    var words: usize = 0;
    for (0..operations) |i| {
        const op = input[1 + 2 * i]; const value = input[2 + 2 * i];
        if (op < 0 or op > 2) return -1;
        if (op == 0) { inserts += 1; if (inserts > MAX_INSERTIONS or value < -2147483648 or value > 2147483647) return -1; }
        else { if (value != 0) return -1; words += 1; }
    }
    if (capacity < words * 8 or (words > 0 and output == null)) return -2;
    var heap: [MAX_INSERTIONS]i64 = @splat(0);
    var size: usize = 0; var out_index: usize = 0;
    const out = if (output) |ptr| ptr else { if (words == 0) return 0; return -2; };
    for (0..operations) |i| {
        const op = input[1 + 2 * i]; const value = input[2 + 2 * i];
        if (op == 0) {
            var at = size; heap[at] = value; size += 1;
            while (at > 0) { const parent = (at - 1) / 2; if (heap[parent] >= heap[at]) break; const t = heap[parent]; heap[parent] = heap[at]; heap[at] = t; at = parent; }
            continue;
        }
        var result: i64 = -9223372036854775808;
        if (size > 0) {
            result = heap[0];
            if (op == 2) { size -= 1; heap[0] = heap[size]; var at: usize = 0;
                while (at < size / 2) { var child = at * 2 + 1; if (child + 1 < size and heap[child + 1] > heap[child]) child += 1;
                    if (heap[at] >= heap[child]) break; const t = heap[at]; heap[at] = heap[child]; heap[child] = t; at = child; }
            }
        }
        storeI64Le(out, out_index * 8, result); out_index += 1;
    }
    return @intCast(words);
}
