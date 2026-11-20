const MAX_ALPHABET: usize = 16;
const MAX_PATTERN: usize = 32;
const MAX_CODES: usize = 32;
const MAX_DICTIONARY: usize = 47;
const MAX_EXPANDED: usize = 528;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT_BYTES: usize = 4232;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lzw_compressed_shift_and_matching(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const alphabet_raw = input[0];
    const pattern_raw = input[1];
    const code_count_raw = input[2];
    if (alphabet_raw < 1 or alphabet_raw > @as(i64, MAX_ALPHABET)
        or pattern_raw < 1 or pattern_raw > @as(i64, MAX_PATTERN)
        or code_count_raw < 0 or code_count_raw > @as(i64, MAX_CODES)) return -1;
    const alphabet_size: usize = @intCast(alphabet_raw);
    const pattern_length: usize = @intCast(pattern_raw);
    const code_count: usize = @intCast(code_count_raw);
    if (length != 3 + pattern_length + code_count) return -1;
    var symbol_mask: [MAX_ALPHABET]u32 = @splat(0);
    for (0..pattern_length) |i| {
        const symbol = input[3 + i];
        if (symbol < 0 or symbol >= alphabet_raw) return -1;
        symbol_mask[@intCast(symbol)] |= @as(u32, 1) << @intCast(i);
    }
    if (code_count > 0) {
        const first_code = input[3 + pattern_length];
        if (first_code < 0 or first_code >= alphabet_raw) return -1;
    }

    var phrase_length: [MAX_DICTIONARY]usize = @splat(0);
    var first_symbol: [MAX_DICTIONARY]u8 = @splat(0);
    var phrase_mask: [MAX_DICTIONARY]u32 = @splat(0);
    var crossing_mask: [MAX_DICTIONARY]u32 = @splat(0);
    var ends_match: [MAX_DICTIONARY]bool = @splat(false);
    var previous_match: [MAX_DICTIONARY]i32 = @splat(-1);
    const top_bit: u32 = @as(u32, 1) << @intCast(pattern_length - 1);
    for (0..alphabet_size) |symbol| {
        phrase_length[symbol] = 1;
        first_symbol[symbol] = @intCast(symbol);
        phrase_mask[symbol] = symbol_mask[symbol];
        if (pattern_length > 1 and (phrase_mask[symbol] & top_bit) != 0)
            crossing_mask[symbol] = @as(u32, 1) << @intCast(pattern_length - 2);
        ends_match[symbol] = pattern_length == 1 and (phrase_mask[symbol] & top_bit) != 0;
    }

    var words: [1 + MAX_EXPANDED]i64 = @splat(0);
    var occurrence_count: usize = 0;
    var node_count = alphabet_size;
    var text_offset: usize = 0;
    var state: u32 = 0;
    var previous_code: i32 = -1;
    for (0..code_count) |token| {
        const code_raw = input[3 + pattern_length + token];
        var current_code: usize = 0;
        if (previous_code < 0) {
            current_code = @intCast(code_raw);
        } else {
            if (code_raw < 0 or code_raw > @as(i64, @intCast(node_count))) return -1;
            var appended: u8 = 0;
            if (code_raw == @as(i64, @intCast(node_count))) {
                appended = first_symbol[@intCast(previous_code)];
                current_code = node_count;
            } else {
                current_code = @intCast(code_raw);
                appended = first_symbol[current_code];
            }
            if (node_count >= MAX_DICTIONARY) return -1;
            const node = node_count;
            node_count += 1;
            const parent: usize = @intCast(previous_code);
            phrase_length[node] = phrase_length[parent] + 1;
            first_symbol[node] = first_symbol[parent];
            phrase_mask[node] = ((phrase_mask[parent] << 1) | 1) & symbol_mask[appended];
            crossing_mask[node] = crossing_mask[parent];
            if (phrase_length[node] < pattern_length and (phrase_mask[node] & top_bit) != 0)
                crossing_mask[node] |= @as(u32, 1) << @intCast(pattern_length - phrase_length[node] - 1);
            ends_match[node] = phrase_length[node] >= pattern_length and (phrase_mask[node] & top_bit) != 0;
            previous_match[node] = if (ends_match[parent]) previous_code else previous_match[parent];
        }

        var crossing = state & crossing_mask[current_code];
        while (crossing != 0) {
            var highest: usize = 0;
            var bits = crossing;
            while ((bits >> 1) != 0) { bits >>= 1; highest += 1; }
            words[1 + occurrence_count] = @as(i64, @intCast(text_offset)) - @as(i64, @intCast(highest + 1));
            occurrence_count += 1;
            crossing &= ~(@as(u32, 1) << @intCast(highest));
        }
        var internal_nodes: [MAX_DICTIONARY]usize = @splat(0);
        var internal_count: usize = 0;
        var node: i32 = if (ends_match[current_code]) @intCast(current_code) else previous_match[current_code];
        while (node >= 0) {
            internal_nodes[internal_count] = @intCast(node);
            internal_count += 1;
            node = previous_match[@intCast(node)];
        }
        while (internal_count > 0) {
            internal_count -= 1;
            const match_node = internal_nodes[internal_count];
            words[1 + occurrence_count] = @as(i64, @intCast(text_offset))
                + @as(i64, @intCast(phrase_length[match_node])) - @as(i64, @intCast(pattern_length));
            occurrence_count += 1;
        }

        const current_length = phrase_length[current_code];
        const shifted: u32 = if (current_length >= pattern_length) 0 else state << @intCast(current_length);
        const fresh: u32 = if (current_length >= pattern_length)
            (if (pattern_length == 32) 0xffffffff else (@as(u32, 1) << @intCast(pattern_length)) - 1)
        else (@as(u32, 1) << @intCast(current_length)) - 1;
        state = (shifted | fresh) & phrase_mask[current_code];
        text_offset += current_length;
        previous_code = @intCast(current_code);
    }
    words[0] = @intCast(occurrence_count);
    const output_bytes = 8 * (1 + occurrence_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..1 + occurrence_count) |word| store_i64_le(&staged, 8 * word, words[word]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
