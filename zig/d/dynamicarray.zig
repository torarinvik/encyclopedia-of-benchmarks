fn writeWord(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

/// Execute append/update/get/remove/size/capacity/empty operations on a bounded dynamic array.
export fn dynamicarray(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 385 or input[0] < 0 or input[0] > 128) return -1;
    var a: [64]i64 = @splat(0);
    var b: [64]i64 = @splat(0);
    var queries: [128]i64 = @splat(0);
    var size: usize = 0;
    var capacity: usize = 0;
    var cursor: usize = 1;
    var query_count: usize = 0;
    var active: usize = 0;
    for (0..@intCast(input[0])) |_| {
        if (cursor >= length) return -1;
        const op = input[cursor]; cursor += 1;
        if (op == 0) {
            if (cursor >= length or size >= 64) return -1;
            if (size == capacity) {
                if (active == 0) { for (0..size) |i| b[i] = a[i]; active = 1; }
                else { for (0..size) |i| a[i] = b[i]; active = 0; }
                capacity = if (capacity == 0) 10 else capacity * 2;
            }
            if (active == 0) a[size] = input[cursor] else b[size] = input[cursor];
            size += 1; cursor += 1;
        } else if (op == 1) {
            if (cursor + 1 >= length) return -1;
            const index_value = input[cursor]; const value = input[cursor + 1]; cursor += 2;
            if (index_value < 0 or index_value >= size) return -1;
            const index: usize = @intCast(index_value);
            if (active == 0) a[index] = value else b[index] = value;
        } else if (op == 2 or op == 3) {
            if (cursor >= length) return -1;
            const index_value = input[cursor]; cursor += 1;
            if (index_value < 0 or index_value >= size) return -1;
            const index: usize = @intCast(index_value);
            if (op == 2) {
                if (query_count >= 128) return -1;
                queries[query_count] = if (active == 0) a[index] else b[index];
                query_count += 1;
            } else {
                if (active == 0) { for (index..size - 1) |i| a[i] = a[i + 1]; }
                else { for (index..size - 1) |i| b[i] = b[i + 1]; }
                size -= 1;
            }
        } else if (op >= 4 and op <= 6) {
            if (query_count >= 128) return -1;
            queries[query_count] = if (op == 4) @intCast(size) else if (op == 5) @intCast(capacity) else if (size == 0) 1 else 0;
            query_count += 1;
        } else return -1;
    }
    if (cursor != length) return -1;
    const words = 3 + query_count + size;
    if (output_capacity < words * 8) return -2;
    writeWord(output, 0, @intCast(query_count));
    for (0..query_count) |i| writeWord(output, i + 1, queries[i]);
    writeWord(output, query_count + 1, @intCast(size));
    writeWord(output, query_count + 2, @intCast(capacity));
    for (0..size) |i| writeWord(output, query_count + 3 + i, if (active == 0) a[i] else b[i]);
    return @intCast(words);
}
