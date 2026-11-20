const MAX_N: usize = 8;
const MAX_VERTICES: usize = 2 * MAX_N + 2;
const MAX_CYCLES: usize = MAX_N + 1;
const MAX_INPUT: usize = MAX_N + 2;
const MAX_OUTPUT_WORDS: usize = 1 + 3 * MAX_CYCLES;
const MAX_OUTPUT: usize = 8 * MAX_OUTPUT_WORDS;

fn storeWord(bytes: []u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| bytes[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn signed_permutation_overlap_forest_components(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    const vertex_count = 2 * n + 2;
    var pi = [_]usize{0} ** MAX_VERTICES;
    pi[vertex_count - 1] = vertex_count - 1;
    var seen: u16 = 0;
    for (0..n) |position| {
        const gene = input[position + 1];
        if (gene == 0 or gene < -n_value or gene > n_value) return -1;
        const absolute: usize = @intCast(if (gene < 0) -gene else gene);
        const bit: u16 = @as(u16, 1) << @intCast(absolute - 1);
        if ((seen & bit) != 0) return -1;
        seen |= bit;
        var left = 2 * absolute - 1;
        var right = 2 * absolute;
        if (gene < 0) {
            const temporary = left;
            left = right;
            right = temporary;
        }
        pi[2 * position + 1] = left;
        pi[2 * position + 2] = right;
    }
    var gray = [_]usize{0} ** MAX_VERTICES;
    for (0..(n + 1)) |pair| {
        const left = pi[2 * pair];
        const right = pi[2 * pair + 1];
        gray[left] = right;
        gray[right] = left;
    }
    var cycle_of = [_]i32{-1} ** MAX_VERTICES;
    var begin = [_]usize{0} ** MAX_CYCLES;
    var end = [_]usize{0} ** MAX_CYCLES;
    var cycle_count: usize = 0;
    for (0..vertex_count) |seed| {
        if (cycle_of[seed] >= 0) continue;
        const cid = cycle_count;
        cycle_count += 1;
        var vertex = seed;
        var low = seed;
        var high = seed;
        while (cycle_of[vertex] < 0) {
            cycle_of[vertex] = @intCast(cid);
            low = @min(low, vertex);
            high = @max(high, vertex);
            vertex = gray[vertex ^ 1];
        }
        begin[cid] = low;
        end[cid] = high;
    }

    var parent = [_]usize{0} ** MAX_CYCLES;
    for (0..cycle_count) |cid| parent[cid] = cid;
    var stack_id = [_]usize{0} ** MAX_CYCLES;
    var stack_begin = [_]usize{0} ** MAX_CYCLES;
    var stack_end = [_]usize{0} ** MAX_CYCLES;
    var top: usize = 0;
    for (0..vertex_count) |vertex| {
        const cid: usize = @intCast(cycle_of[vertex]);
        const low = begin[cid];
        const high = end[cid];
        if (vertex == low) {
            stack_id[top] = cid;
            stack_begin[top] = low;
            stack_end[top] = high;
            top += 1;
        }
        var extent_begin = low;
        var extent_end = high;
        while (top > 0 and stack_begin[top - 1] > low) {
            top -= 1;
            const popped = stack_id[top];
            extent_begin = @min(extent_begin, stack_begin[top]);
            extent_end = @max(extent_end, stack_end[top]);
            parent[popped] = cid;
        }
        if (top == 0) return -1;
        stack_begin[top - 1] = @min(stack_begin[top - 1], extent_begin);
        stack_end[top - 1] = @max(stack_end[top - 1], extent_end);
        if (vertex == stack_end[top - 1]) top -= 1;
    }

    var component = [_]usize{0} ** MAX_CYCLES;
    for (0..cycle_count) |cid| {
        component[cid] = if (parent[cid] == cid) begin[cid] else component[parent[cid]];
    }
    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    words[0] = @intCast(cycle_count);
    for (0..cycle_count) |cid| {
        words[1 + 3 * cid] = @intCast(begin[cid]);
        words[2 + 3 * cid] = @intCast(end[cid]);
        words[3 + 3 * cid] = @intCast(component[cid]);
    }
    const output_bytes = (1 + 3 * cycle_count) * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    for (0..1 + 3 * cycle_count) |word| storeWord(staged[0..], word, words[word]);
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
