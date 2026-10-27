const max_leaves: usize = 8;
const max_nodes: usize = 15;
const max_candidates: usize = 256;
const max_input: usize = 32;
const output_bytes: usize = 32;

const Candidate = struct { height: i64 = 0, width: i64 = 0, mask: u64 = 0 };
const Node = struct {
    op: i64 = -1,
    left: usize = 0,
    right: usize = 0,
    count: usize = 0,
    candidates: [max_candidates]Candidate = [_]Candidate{.{}} ** max_candidates,
};

fn mask_lex_less(a: u64, b: u64, leaves: usize) bool {
    for (0..leaves) |bit| {
        const shift: u6 = @intCast(bit);
        const av = (a >> shift) & 1;
        const bv = (b >> shift) & 1;
        if (av != bv) return av < bv;
    }
    return false;
}

fn prune(node: *Node, leaves: usize) void {
    var dominated = [_]bool{false} ** max_candidates;
    for (0..node.count) |i| {
        const a = node.candidates[i];
        for (0..node.count) |j| {
            if (i == j) continue;
            const b = node.candidates[j];
            if (b.height <= a.height and b.width <= a.width and
                (b.height < a.height or b.width < a.width or
                 mask_lex_less(b.mask, a.mask, leaves) or (b.mask == a.mask and j < i))) {
                dominated[i] = true;
                break;
            }
        }
    }
    var kept: usize = 0;
    for (0..node.count) |i| {
        if (!dominated[i]) {
            node.candidates[kept] = node.candidates[i];
            kept += 1;
        }
    }
    node.count = kept;
}

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits & 255);
        bits >>= 8;
    }
}

export fn slicing_floorplan_stockmeyer(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8) return -1;
    const leaves: usize = @intCast(input[0]);
    var nodes = [_]Node{.{}} ** max_nodes;
    var stack = [_]usize{0} ** max_nodes;
    var stack_size: usize = 0;
    var node_count: usize = 0;
    var leaf_count: usize = 0;
    var internal_count: usize = 0;
    var position: usize = 1;
    while (position < length) {
        const token = input[position];
        position += 1;
        if (token == 2) {
            if (position + 2 > length or leaf_count >= leaves or node_count >= max_nodes) return -1;
            const height = input[position];
            const width = input[position + 1];
            position += 2;
            if (height < 1 or height > 20 or width < 1 or width > 20) return -1;
            nodes[node_count].op = 2;
            nodes[node_count].candidates[0] = .{ .height = height, .width = width, .mask = 0 };
            nodes[node_count].candidates[1] = .{ .height = width, .width = height, .mask = @as(u64, 1) << @intCast(leaf_count) };
            nodes[node_count].count = 2;
            prune(&nodes[node_count], leaves);
            stack[stack_size] = node_count;
            stack_size += 1;
            node_count += 1;
            leaf_count += 1;
        } else if (token == 0 or token == 1) {
            if (stack_size < 2 or internal_count >= leaves - 1 or node_count >= max_nodes) return -1;
            stack_size -= 1;
            const right = stack[stack_size];
            stack_size -= 1;
            const left = stack[stack_size];
            if (nodes[right].op == token) return -1;
            nodes[node_count].op = token;
            nodes[node_count].left = left;
            nodes[node_count].right = right;
            for (0..nodes[left].count) |i| {
                for (0..nodes[right].count) |j| {
                    if (nodes[node_count].count >= max_candidates) return -1;
                    const a = nodes[left].candidates[i];
                    const b = nodes[right].candidates[j];
                    var candidate: Candidate = .{ .mask = a.mask | b.mask };
                    if (token == 0) {
                        candidate.height = @max(a.height, b.height);
                        candidate.width = a.width + b.width;
                    } else {
                        candidate.height = a.height + b.height;
                        candidate.width = @max(a.width, b.width);
                    }
                    const slot = nodes[node_count].count;
                    nodes[node_count].candidates[slot] = candidate;
                    nodes[node_count].count += 1;
                }
            }
            prune(&nodes[node_count], leaves);
            stack[stack_size] = node_count;
            stack_size += 1;
            node_count += 1;
            internal_count += 1;
        } else return -1;
    }
    if (position != length or leaf_count != leaves or internal_count != leaves - 1 or
        node_count != 2 * leaves - 1 or stack_size != 1) return -1;
    const root = nodes[stack[0]];
    if (root.count == 0) return -1;
    var best = root.candidates[0];
    for (1..root.count) |i| {
        const candidate = root.candidates[i];
        const area = candidate.height * candidate.width;
        const best_area = best.height * best.width;
        if (area < best_area or (area == best_area and (candidate.height < best.height or
            (candidate.height == best.height and (candidate.width < best.width or
            (candidate.width == best.width and mask_lex_less(candidate.mask, best.mask, leaves))))))) {
            best = candidate;
        }
    }
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged = [_]u8{0} ** output_bytes;
    store_i64_le(&staged[0], 0, best.height * best.width);
    store_i64_le(&staged[0], 8, best.height);
    store_i64_le(&staged[0], 16, best.width);
    store_i64_le(&staged[0], 24, @intCast(best.mask));
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return output_bytes;
}
