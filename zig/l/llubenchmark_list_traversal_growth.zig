const MAX_LISTS = 4;
const MAX_INITIAL_LENGTH = 4;
const MAX_ITERATIONS = 16;
const MAX_NODES = 36;

fn storeLeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

pub export fn llubenchmark_list_traversal_growth(
    input: [*c]const i64,
    input_length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or input_length != 3) return -1;
    const list_value = input[0];
    const initial_value = input[1];
    const iteration_value = input[2];
    if (list_value < 1 or list_value > MAX_LISTS or
        initial_value < 1 or initial_value > MAX_INITIAL_LENGTH or
        iteration_value < 0 or iteration_value > MAX_ITERATIONS) return -1;
    if (output == null or output_capacity < 16) return -2;
    const list_count: usize = @intCast(list_value);
    const initial_length: usize = @intCast(initial_value);
    const iterations: usize = @intCast(iteration_value);
    var next = [_]i64{-1} ** MAX_NODES;
    var counts = [_]i64{0} ** MAX_NODES;
    var heads = [_]i64{-1} ** MAX_LISTS;
    var tails = [_]i64{-1} ** MAX_LISTS;
    var allocated: usize = 0;
    for (0..initial_length) |_| {
        for (0..list_count) |list| {
            const node = allocated; allocated += 1;
            next[node] = heads[list]; heads[list] = @intCast(node);
            if (tails[list] == -1) tails[list] = @intCast(node);
        }
    }
    var accumulate: i64 = 0;
    var growth_milli: i32 = 0;
    for (0..iterations) |_| {
        for (0..list_count) |list| {
            var node = heads[list];
            while (node != -1) {
                const index: usize = @intCast(node);
                accumulate += counts[index]; counts[index] += 1;
                node = next[index];
            }
        }
        growth_milli += 333;
        const insertions = @divTrunc(growth_milli, 1000);
        growth_milli -= insertions * 1000;
        var ordinal: i32 = insertions;
        while (ordinal > 0) : (ordinal -= 1) {
            for (0..list_count) |list| {
                const node = allocated; allocated += 1;
                counts[node] = @intCast(@as(i32, @intCast(list)) + ordinal);
                next[node] = -1;
                next[@intCast(tails[list])] = @intCast(node);
                tails[list] = @intCast(node);
            }
        }
    }
    storeLeI64(output, 0, accumulate);
    storeLeI64(output, 8, @intCast(allocated));
    return 2;
}
