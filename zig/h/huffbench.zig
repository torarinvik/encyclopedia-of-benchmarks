const DATA_BYTES: usize = 4096;
const MIN_PASSES: i64 = 1;
const MAX_PASSES: i64 = 30;

fn heapAdjust(frequency: []const usize, heap: []usize, active: usize, one_based: usize) void {
    const value = heap[one_based - 1];
    var index = one_based;
    while (index <= active / 2) {
        var child = index * 2;
        if (child < active and frequency[heap[child - 1]] > frequency[heap[child]]) child += 1;
        if (frequency[value] < frequency[heap[child - 1]]) break;
        heap[index - 1] = heap[child - 1];
        index = child;
    }
    heap[index - 1] = value;
}

fn random4(seed: *i64) usize {
    seed.* ^= 123459876;
    const quotient = @divTrunc(seed.*, 127773);
    seed.* = 16807 * (seed.* - quotient * 127773) - 2836 * quotient;
    if (seed.* < 0) seed.* += 2147483647;
    const result: usize = @intCast(@mod(seed.*, 32));
    seed.* ^= 123459876;
    return result;
}

fn compdecomp(data: []u8, compressed: []u8, compressed_length: *usize, checksum: *u32) bool {
    var frequency: [512]usize = @splat(0);
    var heap: [256]usize = @splat(0);
    var link: [512]i64 = @splat(0);
    var code: [256]u32 = @splat(0);
    var code_length: [256]usize = @splat(0);
    for (data) |byte| frequency[byte] += 1;

    var active: usize = 0;
    for (0..256) |symbol| {
        if (frequency[symbol] != 0) {
            heap[active] = symbol;
            active += 1;
        }
    }
    var index = active;
    while (index > 0) : (index -= 1) heapAdjust(frequency[0..], heap[0..], active, index);
    while (active > 1) {
        active -= 1;
        const first = heap[0];
        heap[0] = heap[active];
        heapAdjust(frequency[0..], heap[0..], active, 1);
        const parent = 256 + active;
        frequency[parent] = frequency[heap[0]] + frequency[first];
        link[first] = @intCast(parent);
        link[heap[0]] = -@as(i64, @intCast(parent));
        heap[0] = parent;
        heapAdjust(frequency[0..], heap[0..], active, 1);
    }
    link[256 + active] = 0;

    for (0..256) |symbol| {
        if (frequency[symbol] == 0) continue;
        var depth: usize = 0;
        var bit: u32 = 1;
        var value: u32 = 0;
        var parent = link[symbol];
        while (parent != 0) {
            if (parent < 0) {
                value += bit;
                parent = -parent;
            }
            parent = link[@intCast(parent)];
            bit <<= 1;
            depth += 1;
        }
        code[symbol] = value;
        code_length[symbol] = depth;
    }

    var compressed_used: usize = 0;
    var bout: u8 = 0;
    var bit_index: i64 = -1;
    for (data) |byte| {
        const symbol: usize = byte;
        var mask: u32 = @as(u32, 1) << @intCast(code_length[symbol] - 1);
        for (0..code_length[symbol]) |_| {
            if (bit_index == 7) {
                compressed[compressed_used] = bout;
                compressed_used += 1;
                bit_index = 0;
                bout = 0;
            } else {
                bit_index += 1;
                bout <<= 1;
            }
            if ((code[symbol] & mask) != 0) bout |= 1;
            mask >>= 1;
        }
    }
    bout <<= @intCast(7 - bit_index);
    compressed[compressed_used] = bout;
    compressed_used += 1;

    var child_zero: [512]i64 = @splat(-1);
    var child_one: [512]i64 = @splat(-1);
    var decoded_symbol: [512]i64 = @splat(-1);
    var node_count: usize = 1;
    for (0..256) |symbol| {
        if (frequency[symbol] == 0) continue;
        var node: usize = 0;
        var bit: i64 = @as(i64, @intCast(code_length[symbol])) - 1;
        while (bit >= 0) : (bit -= 1) {
            const direction: usize = @intCast((code[symbol] >> @intCast(bit)) & 1);
            var next_node = if (direction == 0) child_zero[node] else child_one[node];
            if (next_node < 0) {
                next_node = @intCast(node_count);
                if (direction == 0) child_zero[node] = next_node else child_one[node] = next_node;
                node_count += 1;
            }
            node = @intCast(next_node);
        }
        decoded_symbol[node] = @intCast(symbol);
    }

    var decoded: usize = 0;
    var sum: u64 = 0;
    var node: usize = 0;
    index = 0;
    while (index < compressed_used and decoded < DATA_BYTES) : (index += 1) {
        var bit: i64 = 7;
        while (bit >= 0 and decoded < DATA_BYTES) : (bit -= 1) {
            const direction: usize = @intCast((compressed[index] >> @intCast(bit)) & 1);
            const next_node = if (direction == 0) child_zero[node] else child_one[node];
            if (next_node < 0) return false;
            node = @intCast(next_node);
            if (decoded_symbol[node] >= 0) {
                data[decoded] = @intCast(decoded_symbol[node]);
                sum += @intCast(decoded_symbol[node]);
                decoded += 1;
                node = 0;
            }
        }
    }
    if (decoded != DATA_BYTES) return false;
    compressed_length.* = compressed_used;
    checksum.* = @truncate(sum);
    return true;
}

fn appendLiteral(output: []u8, position_input: usize, literal: []const u8) usize {
    var position = position_input;
    for (literal) |byte| {
        output[position] = byte;
        position += 1;
    }
    return position;
}

fn appendDecimal(output: []u8, position_input: usize, value_input: u32) usize {
    var reversed: [10]u8 = undefined;
    var digits: usize = 0;
    var value = value_input;
    while (true) {
        reversed[digits] = '0' + @as(u8, @intCast(value % 10));
        digits += 1;
        value /= 10;
        if (value == 0) break;
    }
    var position = position_input;
    while (digits > 0) {
        digits -= 1;
        output[position] = reversed[digits];
        position += 1;
    }
    return position;
}

export fn coyote_huffbench(passes: i64, output: [*c]u8, output_capacity: usize) i64 {
    if (passes < MIN_PASSES or passes > MAX_PASSES) return -1;
    if (output == null) return -2;

    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    var data: [DATA_BYTES]u8 = undefined;
    var seed: i64 = 1325;
    for (0..DATA_BYTES) |index| data[index] = alphabet[random4(&seed)];

    var compressed: [DATA_BYTES + 1]u8 = @splat(0);
    var compressed_length: usize = 0;
    var checksum: u32 = 0;
    for (0..@intCast(passes)) |_| {
        if (!compdecomp(data[0..], compressed[0..], &compressed_length, &checksum)) return -1;
    }

    var staged: [52]u8 = undefined;
    var used = appendLiteral(staged[0..], 0, "Huffbench passes=");
    used = appendDecimal(staged[0..], used, @intCast(passes));
    used = appendLiteral(staged[0..], used, " compressed=");
    used = appendDecimal(staged[0..], used, @intCast(compressed_length));
    used = appendLiteral(staged[0..], used, " checksum=");
    used = appendDecimal(staged[0..], used, checksum);
    staged[used] = '\n';
    used += 1;
    if (output_capacity < used) return -2;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
