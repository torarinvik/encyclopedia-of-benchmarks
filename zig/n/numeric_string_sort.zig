/// Sort decimal tokens by the pinned normalized-length/lexicographic comparator.
const MAX_ITEMS: usize = 64;
const MAX_TOKEN_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 2113;
const MAX_OUTPUT_LENGTH: usize = 2111;

const TokenRef = struct {
    start: usize,
    length: usize,
    normalized_start: usize,
    normalized_length: usize,
};

fn tokenLess(values: [*c]const i64, left: TokenRef, right: TokenRef) bool {
    if (left.normalized_length != right.normalized_length)
        return left.normalized_length < right.normalized_length;
    for (0..left.normalized_length) |index| {
        const a = values[left.normalized_start + index];
        const b = values[right.normalized_start + index];
        if (a != b) return a < b;
    }
    return false;
}

export fn numeric_string_sort(values: [*c]const i64, length: usize,
                              output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT_LENGTH + 1) return -1;
    if (values[0] < 0 or values[0] > MAX_ITEMS) return -1;
    const count: usize = @intCast(values[0]);
    var tokens: [MAX_ITEMS]TokenRef = undefined;
    var order: [MAX_ITEMS]usize = undefined;
    var cursor: usize = 1;
    var output_length: usize = if (count == 0) 0 else count - 1;

    for (0..count) |item| {
        if (cursor >= length) return -1;
        const raw_length = values[cursor];
        cursor += 1;
        if (raw_length < 1 or raw_length > MAX_TOKEN_LENGTH) return -1;
        const token_length: usize = @intCast(raw_length);
        if (token_length > length - cursor) return -1;
        const start = cursor;
        for (0..token_length) |offset| {
            if (values[start + offset] < '0' or values[start + offset] > '9') return -1;
        }
        var zeros: usize = 0;
        while (zeros < token_length and values[start + zeros] == '0') : (zeros += 1) {}
        const current = TokenRef{ .start = start, .length = token_length,
            .normalized_start = start + zeros, .normalized_length = token_length - zeros };
        tokens[item] = current;
        for (0..item) |previous_index| {
            const previous = tokens[previous_index];
            if (previous.normalized_length != current.normalized_length) continue;
            var equal = true;
            for (0..current.normalized_length) |offset| {
                if (values[previous.normalized_start + offset] != values[current.normalized_start + offset]) {
                    equal = false;
                    break;
                }
            }
            if (equal) {
                if (previous.length != token_length) return -1;
                for (0..token_length) |offset| {
                    if (values[previous.start + offset] != values[start + offset]) return -1;
                }
            }
        }
        output_length += token_length;
        cursor += token_length;
        order[item] = item;
    }
    if (cursor != length or output_length > MAX_OUTPUT_LENGTH) return -1;

    for (1..count) |item| {
        const key = order[item];
        var position = item;
        while (position > 0 and tokenLess(values, tokens[key], tokens[order[position - 1]])) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }
    if ((output == null and output_length != 0) or output_capacity < output_length) return -2;
    var written: usize = 0;
    for (0..count) |item| {
        if (item != 0) { output[written] = ' '; written += 1; }
        const token = tokens[order[item]];
        for (0..token.length) |offset| {
            output[written] = @intCast(values[token.start + offset]);
            written += 1;
        }
    }
    return @intCast(output_length);
}
