/// Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt.
const max_ref: usize = 32;
const max_query: usize = 32;
const alphabet: usize = 5;
const max_nodes: usize = 1 + max_ref * (max_ref + 3) / 2;
const max_matches: usize = max_ref * max_query;

fn suffixLess(reference: [*]const i64, length: usize, left: usize, right: usize) bool {
    var a = left;
    var b = right;
    while (a < length and b < length and reference[a] == reference[b]) : ({ a += 1; b += 1; }) {}
    if (a == length and b == length) return false;
    if (a == length) return false;
    if (b == length) return true;
    return reference[a] < reference[b];
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rodinia_mummergpu(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length < 5 or length > 3 + max_ref + max_query) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_ref)) or input[1] < 1 or input[1] > @as(i64, @intCast(max_query)) or input[2] < 1 or input[2] > @as(i64, @intCast(max_query))) return -1;
    const ref_len: usize = @intCast(input[0]);
    const query_len: usize = @intCast(input[1]);
    const min_len: usize = @intCast(input[2]);
    if (length != 3 + ref_len + query_len) return -1;
    var reference: [max_ref]i64 = @splat(0);
    var query: [max_query]i64 = @splat(0);
    for (0..ref_len) |i| { const code = input[3 + i]; if (code < 0 or code > 3) return -1; reference[i] = code; }
    for (0..query_len) |i| { const code = input[3 + ref_len + i]; if (code < 0 or code > 3) return -1; query[i] = code; }

    var children: [max_nodes * alphabet]i32 = @splat(-1);
    var path_node: [max_ref * (max_ref + 1)]i32 = @splat(-1);
    var suffix_order: [max_ref]usize = @splat(0);
    var node_count: usize = 1;
    for (0..ref_len) |start| {
        var node: usize = 0;
        var depth: usize = 0;
        path_node[start * (max_ref + 1)] = 0;
        for (start..ref_len) |pos| {
            const slot = node * alphabet + @as(usize, @intCast(reference[pos]));
            if (children[slot] < 0) {
                const fresh = node_count;
                node_count += 1;
                children[slot] = @intCast(fresh);
                for (0..alphabet) |symbol| children[fresh * alphabet + symbol] = -1;
            }
            node = @intCast(children[slot]);
            depth += 1;
            path_node[start * (max_ref + 1) + depth] = @intCast(node);
        }
        const terminal = node * alphabet + 4;
        if (children[terminal] < 0) {
            const fresh = node_count;
            node_count += 1;
            children[terminal] = @intCast(fresh);
            for (0..alphabet) |symbol| children[fresh * alphabet + symbol] = -1;
        }
    }
    for (0..ref_len) |i| suffix_order[i] = i;
    for (1..ref_len) |i| {
        const key = suffix_order[i];
        var j = i;
        while (j > 0 and suffixLess(&reference, ref_len, key, suffix_order[j - 1])) : (j -= 1) suffix_order[j] = suffix_order[j - 1];
        suffix_order[j] = key;
    }

    var records: [max_matches * 3]i64 = @splat(0);
    var match_count: usize = 0;
    for (0..query_len) |qstart| {
        var candidate: [max_ref]i32 = @splat(-1);
        var node: usize = 0;
        var depth: usize = 0;
        while (true) {
            const query_has_next = qstart + depth < query_len;
            for (0..ref_len) |rstart| {
                if (path_node[rstart * (max_ref + 1) + depth] != @as(i32, @intCast(node))) continue;
                const suffix_ends = rstart + depth == ref_len;
                if (suffix_ends or !query_has_next or reference[rstart + depth] != query[qstart + depth]) candidate[rstart] = @intCast(depth);
            }
            if (!query_has_next) break;
            const slot = node * alphabet + @as(usize, @intCast(query[qstart + depth]));
            if (children[slot] < 0) break;
            node = @intCast(children[slot]);
            depth += 1;
        }
        for (0..ref_len) |order| {
            const rstart = suffix_order[order];
            const match_len = candidate[rstart];
            if (match_len < @as(i32, @intCast(min_len))) continue;
            if (qstart > 0 and rstart > 0 and query[qstart - 1] == reference[rstart - 1]) continue;
            records[3 * match_count] = @intCast(rstart + 1);
            records[3 * match_count + 1] = @intCast(qstart + 1);
            records[3 * match_count + 2] = @intCast(match_len);
            match_count += 1;
        }
    }
    const output_bytes = match_count * 24;
    if (@intFromPtr(output) == 0 or capacity < output_bytes) return -2;
    for (0..3 * match_count) |i| putI64(output, i * 8, records[i]);
    return @intCast(output_bytes);
}
