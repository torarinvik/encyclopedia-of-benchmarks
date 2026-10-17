const std = @import("std");
const MAX_TEXT_LENGTH: usize = 64;
const MAX_NODES: usize = 1 + 2 * MAX_TEXT_LENGTH;
const MAX_EDGES: usize = 2 * MAX_TEXT_LENGTH;
const MAX_OUTPUT_BYTES: usize = 5176;
const NONE: usize = std.math.maxInt(usize);

fn appendEdge(parent: usize, child: usize, first: *[MAX_NODES]usize,
    last: *[MAX_NODES]usize, edge_child: *[MAX_EDGES]usize,
    edge_next: *[MAX_EDGES]usize, edge_count: *usize) void {
    const edge = edge_count.*;
    edge_count.* += 1;
    edge_child[edge] = child;
    edge_next[edge] = NONE;
    if (last[parent] == NONE) {
        first[parent] = edge;
    } else {
        edge_next[last[parent]] = edge;
    }
    last[parent] = edge;
}

fn writeU64(output: *[MAX_OUTPUT_BYTES]u8, position: *usize, value: u64) void {
    for (0..8) |shift| {
        output[position.*] = @truncate(value >> @intCast(shift * 8));
        position.* += 1;
    }
}

export fn suffix_tree_construct(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > 66) return -1;
    const text_length_value = values[0];
    if (text_length_value < 0 or text_length_value > 64) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (input_length != 1 + text_length) return -1;
    var text = [_]u8{0} ** MAX_TEXT_LENGTH;
    for (0..text_length) |index| {
        const code = values[1 + index];
        if (code < 0 or code > 127) return -1;
        text[index] = @intCast(code);
    }

    var labels = [_][MAX_TEXT_LENGTH]u8{[_]u8{0} ** MAX_TEXT_LENGTH} ** MAX_NODES;
    var label_lengths = [_]usize{0} ** MAX_NODES;
    var first_edge = [_]usize{NONE} ** MAX_NODES;
    var last_edge = [_]usize{NONE} ** MAX_NODES;
    var edge_child = [_]usize{0} ** MAX_EDGES;
    var edge_next = [_]usize{NONE} ** MAX_EDGES;
    var node_count: usize = 1;
    var edge_count: usize = 0;

    for (0..text_length) |start| {
        const suffix_length = text_length - start;
        var offset: usize = 0;
        var node: usize = 0;
        while (offset < suffix_length) {
            const first_code = text[start + offset];
            var selected = first_edge[node];
            while (selected != NONE and labels[edge_child[selected]][0] != first_code) {
                selected = edge_next[selected];
            }
            if (selected == NONE) {
                const leaf = node_count;
                node_count += 1;
                const leaf_length = suffix_length - offset;
                for (0..leaf_length) |index| labels[leaf][index] = text[start + offset + index];
                label_lengths[leaf] = leaf_length;
                appendEdge(node, leaf, &first_edge, &last_edge, &edge_child, &edge_next, &edge_count);
                break;
            }

            const child = edge_child[selected];
            const child_length = label_lengths[child];
            var common: usize = 0;
            while (common < child_length and offset + common < suffix_length and
                labels[child][common] == text[start + offset + common]) : (common += 1) {}
            if (common == child_length) {
                offset += common;
                node = child;
                continue;
            }

            const split = node_count;
            node_count += 1;
            for (0..common) |index| labels[split][index] = labels[child][index];
            label_lengths[split] = common;
            const remainder_length = child_length - common;
            for (0..remainder_length) |index| labels[child][index] = labels[child][common + index];
            label_lengths[child] = remainder_length;
            edge_child[selected] = split;
            appendEdge(split, child, &first_edge, &last_edge, &edge_child, &edge_next, &edge_count);
            offset += common;
            node = split;
        }
    }

    var bytes = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var written: usize = 0;
    writeU64(&bytes, &written, @intCast(node_count));
    for (0..node_count) |node| {
        const label_length = label_lengths[node];
        writeU64(&bytes, &written, @intCast(label_length));
        for (0..label_length) |index| {
            bytes[written] = labels[node][index];
            written += 1;
        }
        var child_count: u64 = 0;
        var edge = first_edge[node];
        while (edge != NONE) : (edge = edge_next[edge]) child_count += 1;
        writeU64(&bytes, &written, child_count);
        edge = first_edge[node];
        while (edge != NONE) : (edge = edge_next[edge]) {
            writeU64(&bytes, &written, @intCast(edge_child[edge]));
        }
    }
    const destination = output orelse return -2;
    if (output_capacity < written) return -2;
    @memcpy(destination[0..written], bytes[0..written]);
    return @intCast(written);
}
