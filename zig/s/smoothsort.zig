const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn sift(values: *[MAX_COUNT]i64, root_arg: usize, order_arg: usize, leonardo: *const [16]usize) void {
    var root = root_arg; var order = order_arg;
    while (order > 1) {
        const right = root - 1; const left = root - 1 - leonardo[order - 2];
        if (!(values[left] < values[right]) and values[root] < values[left]) { const t = values[root]; values[root] = values[left]; values[left] = t; root = left; order -= 1; }
        else if (values[left] < values[right] and values[root] < values[right]) { const t = values[root]; values[root] = values[right]; values[right] = t; root = right; order -= 2; }
        else break;
    }
}
fn trinkle(values: *[MAX_COUNT]i64, position_arg: usize, orders: *[MAX_COUNT]usize, index_arg: usize, leonardo: *const [16]usize) void {
    var position = position_arg; var index = index_arg;
    while (index > 0) {
        const previous = position - leonardo[orders[index]];
        if (!(values[position] < values[previous])) break;
        if (orders[index] > 1) {
            const right = position - 1; const left = position - 1 - leonardo[orders[index] - 2];
            if (!(values[right] < values[previous]) or !(values[left] < values[previous])) break;
        }
        const t = values[position]; values[position] = values[previous]; values[previous] = t; position = previous; index -= 1;
    }
    sift(values, position, orders[index], leonardo);
}
fn smoothSort(values: *[MAX_COUNT]i64, count: usize) void {
    if (count < 2) return;
    var leonardo: [16]usize = @splat(0); leonardo[0] = 1; leonardo[1] = 1;
    for (2..16) |i| leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1;
    var orders: [MAX_COUNT]usize = @splat(0); var heap_count: usize = 0;
    for (0..count) |position| {
        if (heap_count >= 2 and orders[heap_count - 2] == orders[heap_count - 1] + 1) { heap_count -= 1; orders[heap_count - 1] += 1; }
        else if (heap_count > 0 and orders[heap_count - 1] == 1) { orders[heap_count] = 0; heap_count += 1; }
        else { orders[heap_count] = 1; heap_count += 1; }
        trinkle(values, position, &orders, heap_count - 1, &leonardo);
    }
    var position = count;
    while (position > 0) {
        position -= 1; heap_count -= 1; const order = orders[heap_count];
        if (order > 1) {
            const right_order = order - 2; const left_order = order - 1;
            const right_position = position - 1; const left_position = position - 1 - leonardo[right_order];
            orders[heap_count] = left_order; heap_count += 1; trinkle(values, left_position, &orders, heap_count - 1, &leonardo);
            orders[heap_count] = right_order; heap_count += 1; trinkle(values, right_position, &orders, heap_count - 1, &leonardo);
        }
    }
}
fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn smoothsort(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, MAX_COUNT)) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + count or length > MAX_COUNT + 1) return -1;
    var values: [MAX_COUNT]i64 = @splat(0);
    for (0..count) |i| values[i] = input[i + 1];
    smoothSort(&values, count);
    const output_bytes = count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..count) |i| storeI64(output, i * 8, values[i]);
    return @intCast(output_bytes);
}
