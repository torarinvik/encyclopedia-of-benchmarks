const MAX_N: usize = 16;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 52;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn isMarked(bitmap: u32, vertex: usize) bool {
    return (bitmap & (@as(u32, 1) << @intCast(vertex))) != 0;
}

fn shortcutInverse(target: usize, n: usize, successor: *const [MAX_N]usize,
    bitmap: u32, shortcuts: *const [MAX_N]usize) ?usize {
    var marker = target;
    var steps: usize = 0;
    while (steps < n and !isMarked(bitmap, marker)) : (steps += 1) {
        marker = successor[marker];
    }
    if (!isMarked(bitmap, marker)) {
        var previous = target;
        var current = successor[target];
        while (current != target) {
            previous = current;
            current = successor[current];
        }
        return previous;
    }
    var rank: usize = 0;
    for (0..marker) |vertex| {
        if (isMarked(bitmap, vertex)) rank += 1;
    }
    var current = shortcuts[rank];
    var previous = current;
    current = successor[current];
    for (0..n) |_| {
        if (current == target) return previous;
        previous = current;
        current = successor[current];
    }
    return null;
}

export fn permutation_shortcut_index(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const stride_raw = input[1];
    if (n_raw < 1 or n_raw > MAX_N or stride_raw < 1 or stride_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    const stride: usize = @intCast(stride_raw);
    const query_at = 2 + n;
    if (length <= query_at) return -1;
    const query_raw = input[query_at];
    if (query_raw < 0 or query_raw > MAX_QUERIES or length != query_at + 1 + 2 * @as(usize, @intCast(query_raw))) return -1;
    const query_count: usize = @intCast(query_raw);
    var successor: [MAX_N]usize = @splat(0);
    var seen: [MAX_N]bool = @splat(false);
    for (0..n) |vertex| {
        const value = input[2 + vertex];
        if (value < 1 or value > n_raw or seen[@intCast(value - 1)]) return -1;
        seen[@intCast(value - 1)] = true;
        successor[vertex] = @intCast(value - 1);
    }
    for (0..query_count) |query| {
        const op = input[query_at + 1 + 2 * query];
        const index = input[query_at + 2 + 2 * query];
        if ((op != 0 and op != 1) or index < 1 or index > n_raw) return -1;
    }

    var visited: [MAX_N]bool = @splat(false);
    var back_pointer: [MAX_N]usize = @splat(0);
    var bitmap: u32 = 0;
    for (0..n) |start| {
        if (visited[start]) continue;
        var cycle: [MAX_N]usize = @splat(0);
        var cycle_length: usize = 0;
        var current = start;
        while (!visited[current]) {
            visited[current] = true;
            cycle[cycle_length] = current;
            cycle_length += 1;
            current = successor[current];
        }
        if (cycle_length >= stride) {
            var offset: usize = 0;
            while (offset < cycle_length) : (offset += stride) {
                const vertex = cycle[offset];
                bitmap |= @as(u32, 1) << @intCast(vertex);
                const tmod = stride % cycle_length;
                const back_offset = if (offset >= tmod) offset - tmod else cycle_length - (tmod - offset);
                back_pointer[vertex] = cycle[back_offset];
            }
        }
    }
    var shortcuts: [MAX_N]usize = @splat(0);
    var shortcut_count: usize = 0;
    for (0..n) |vertex| {
        if (isMarked(bitmap, vertex)) {
            shortcuts[shortcut_count] = back_pointer[vertex];
            shortcut_count += 1;
        }
    }
    var answers: [MAX_QUERIES]i64 = @splat(0);
    for (0..query_count) |query| {
        const op = input[query_at + 1 + 2 * query];
        const target: usize = @intCast(input[query_at + 2 + 2 * query] - 1);
        const answer = if (op == 0) successor[target]
            else shortcutInverse(target, n, &successor, bitmap, &shortcuts) orelse return -1;
        answers[query] = @intCast(answer + 1);
    }
    const bytes = query_count * 8;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..query_count) |query| storeI64Le(output, query * 8, answers[query]);
    return @intCast(bytes);
}
