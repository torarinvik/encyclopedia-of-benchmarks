const MAX_ITEMS: usize = 4096;
const MAX_CODES: usize = 4352;
const MAX_OUTPUT: usize = 65536;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashI64(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    }
    return result;
}

fn hashRecord(mode: i64, values: []const i64) i64 {
    var hash = hashI64(FNV_OFFSET, mode);
    hash = hashI64(hash, @intCast(values.len));
    for (values) |value| hash = hashI64(hash, value);
    return @intCast(hash & 0x7fffffffffffffff);
}

fn expandCode(code: usize, dictionary_size: usize, prefix: *const [MAX_CODES]i32,
    suffix: *const [MAX_CODES]u8, phrase: *[MAX_CODES]u8) isize {
    var length: usize = 0;
    var current = code;
    while (current >= 256) {
        if (current >= dictionary_size or length >= MAX_CODES) return -1;
        phrase[length] = suffix[current];
        length += 1;
        if (prefix[current] < 0) return -1;
        current = @intCast(prefix[current]);
    }
    if (length >= MAX_CODES) return -1;
    phrase[length] = @intCast(current);
    length += 1;
    var left: usize = 0;
    var right = length - 1;
    while (left < right) : (left += 1) {
        const byte = phrase[left];
        phrase[left] = phrase[right];
        phrase[right] = byte;
        right -= 1;
    }
    return @intCast(length);
}

export fn lzw(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_ITEMS + 2) return -1;
    const mode = values[0];
    const count64 = values[1];
    if ((mode != 0 and mode != 1) or count64 < 0 or count64 > MAX_ITEMS or length != @as(usize, @intCast(count64)) + 2) return -1;
    const count: usize = @intCast(count64);

    var prefix: [MAX_CODES]i32 = undefined;
    var next_sibling: [MAX_CODES]i32 = undefined;
    var first_child: [MAX_CODES]i32 = undefined;
    var suffix: [MAX_CODES]u8 = undefined;
    var first_symbol: [MAX_CODES]u8 = undefined;
    for (0..MAX_CODES) |i| {
        prefix[i] = -1;
        next_sibling[i] = -1;
        first_child[i] = -1;
        suffix[i] = 0;
        first_symbol[i] = 0;
    }
    for (0..256) |code| {
        suffix[code] = @intCast(code);
        first_symbol[code] = @intCast(code);
    }

    if (mode == 0) {
        for (0..count) |i| if (values[2 + i] < 0 or values[2 + i] > 127) return -1;
        var codes: [MAX_ITEMS]i64 = undefined;
        var code_count: usize = 0;
        if (count > 0) {
            var dictionary_size: usize = 256;
            var current: usize = @intCast(values[2]);
            for (1..count) |i| {
                const byte: u8 = @intCast(values[2 + i]);
                var match = first_child[current];
                while (match >= 0 and suffix[@intCast(match)] != byte) match = next_sibling[@intCast(match)];
                if (match >= 0) {
                    current = @intCast(match);
                } else {
                    codes[code_count] = @intCast(current);
                    code_count += 1;
                    if (dictionary_size >= MAX_CODES) return -1;
                    prefix[dictionary_size] = @intCast(current);
                    suffix[dictionary_size] = byte;
                    first_symbol[dictionary_size] = first_symbol[current];
                    next_sibling[dictionary_size] = first_child[current];
                    first_child[current] = @intCast(dictionary_size);
                    dictionary_size += 1;
                    current = byte;
                }
            }
            codes[code_count] = @intCast(current);
            code_count += 1;
        }
        return hashRecord(0, codes[0..code_count]);
    }

    for (0..count) |i| if (values[2 + i] < 0 or values[2 + i] >= MAX_CODES) return -1;
    if (count == 0) return hashRecord(1, &[_]i64{});
    const first_code: usize = @intCast(values[2]);
    if (first_code > 127) return -1;
    var decoded: [MAX_OUTPUT]u8 = undefined;
    var phrase: [MAX_CODES]u8 = undefined;
    decoded[0] = @intCast(first_code);
    var decoded_length: usize = 1;
    var dictionary_size: usize = 256;
    var previous = first_code;
    for (1..count) |i| {
        const code: usize = @intCast(values[2 + i]);
        var phrase_length: usize = undefined;
        if (code < dictionary_size) {
            const expanded = expandCode(code, dictionary_size, &prefix, &suffix, &phrase);
            if (expanded < 0) return -1;
            phrase_length = @intCast(expanded);
        } else if (code == dictionary_size) {
            const expanded = expandCode(previous, dictionary_size, &prefix, &suffix, &phrase);
            if (expanded < 0) return -1;
            phrase_length = @intCast(expanded);
            if (phrase_length >= MAX_CODES) return -1;
            phrase[phrase_length] = first_symbol[previous];
            phrase_length += 1;
        } else return -1;

        if (decoded_length > MAX_OUTPUT - phrase_length) return -1;
        for (0..phrase_length) |j| if (phrase[j] > 127) return -1;
        @memcpy(decoded[decoded_length .. decoded_length + phrase_length], phrase[0..phrase_length]);
        decoded_length += phrase_length;
        if (dictionary_size >= MAX_CODES) return -1;
        const next_byte = if (code == dictionary_size) first_symbol[previous] else first_symbol[code];
        prefix[dictionary_size] = @intCast(previous);
        suffix[dictionary_size] = next_byte;
        first_symbol[dictionary_size] = first_symbol[previous];
        dictionary_size += 1;
        previous = code;
    }
    var hash = hashI64(FNV_OFFSET, 1);
    hash = hashI64(hash, @intCast(decoded_length));
    for (decoded[0..decoded_length]) |byte| hash = hashI64(hash, @as(i64, byte));
    return @intCast(hash & 0x7fffffffffffffff);
}
