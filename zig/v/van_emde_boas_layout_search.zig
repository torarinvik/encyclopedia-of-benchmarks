const MAX_HEIGHT: usize = 4;
const MAX_NODES: usize = 15;
const MAX_QUERIES: usize = 4;
const MAX_WORDS: usize = 41;
const MAX_PARSEABLE: usize = 2 + MAX_QUERIES + 1;

fn fillKeys(keys: *[MAX_NODES + 1]i64, heap: usize, low: i64, high: i64) void {
    if (low > high) return;
    const middle = low + @divTrunc(high - low, 2);
    keys.*[heap] = middle;
    fillKeys(keys, heap * 2, low, middle - 1);
    fillKeys(keys, heap * 2 + 1, middle + 1, high);
}

fn emitLayout(order: *[MAX_NODES]i64, used: *usize,
    root: usize, height: usize) void {
    if (height == 1) {
        order.*[used.*] = @intCast(root);
        used.* += 1;
        return;
    }
    const top_height = height / 2;
    const bottom_height = height - top_height;
    emitLayout(order, used, root, top_height);
    const bottom_count = @as(usize, 1) << @intCast(top_height);
    for (0..bottom_count) |offset| {
        emitLayout(order, used, root * bottom_count + offset, bottom_height);
    }
}

pub export fn van_emde_boas_layout_search(
    input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_PARSEABLE) return -1;
    const height_value = input[0];
    const query_value = input[1];
    if (height_value < 1 or height_value > @as(i64, @intCast(MAX_HEIGHT)) or
        query_value < 0 or query_value > @as(i64, @intCast(MAX_QUERIES))) return -1;
    const height: usize = @intCast(height_value);
    const query_count: usize = @intCast(query_value);
    if (length != 2 + query_count) return -1;
    const node_count = (@as(usize, 1) << @intCast(height)) - 1;
    for (0..query_count) |query| {
        if (input[2 + query] < -1 or input[2 + query] > @as(i64, @intCast(node_count))) return -1;
    }

    var order: [MAX_NODES]i64 = @splat(0);
    var keys: [MAX_NODES + 1]i64 = @splat(0);
    var slots: [MAX_NODES + 1]i64 = @splat(0);
    var staged: [MAX_WORDS]i64 = @splat(0);
    var used: usize = 0;
    emitLayout(&order, &used, 1, height);
    fillKeys(&keys, 1, 0, @as(i64, @intCast(node_count)) - 1);
    for (0..node_count) |slot| slots[@intCast(order[slot])] = @intCast(slot);

    var out: usize = 0;
    staged[out] = @intCast(node_count);
    out += 1;
    for (0..node_count) |slot| {
        staged[out] = order[slot];
        out += 1;
    }
    staged[out] = @intCast(query_count);
    out += 1;
    for (0..query_count) |query| {
        const key = input[2 + query];
        var heap: usize = 1;
        const path_start = out;
        out += 1;
        var path_length: usize = 0;
        var found: i64 = -1;
        while (heap <= node_count) {
            staged[out] = slots[heap];
            out += 1;
            path_length += 1;
            if (key == keys[heap]) {
                found = @intCast(heap);
                break;
            }
            if (key < keys[heap]) heap *= 2 else heap = heap * 2 + 1;
        }
        staged[path_start] = @intCast(path_length);
        staged[out] = found;
        out += 1;
    }
    const required = out * 8;
    if (capacity < required) return -2;
    const output = output_opt orelse return -2;
    for (0..out) |word| {
        const bytes = @as(u64, @bitCast(staged[word]));
        for (0..8) |byte| output[word * 8 + byte] = @truncate(bytes >> @intCast(8 * byte));
    }
    return @intCast(required);
}
