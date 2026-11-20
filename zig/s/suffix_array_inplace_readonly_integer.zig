const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const PACKED_FIELD_WORDS: usize = 4;
const PACKED_LIST_WORDS: usize = 2;

const PackedFields = struct { word: [PACKED_FIELD_WORDS]u64 = @splat(0) };
const InputView = struct {
    raw: [*]const i64,
    packed: [*]const u64,
    raw_length: usize,
    raw_offset: usize,
    is_packed: bool,
};

fn fieldGet(fields: *const PackedFields, index: usize) i32 {
    const value: i32 = @intCast((fields.word[index / 9] >> @intCast((index % 9) * 7)) & 127);
    return if (value == 127) -1 else value;
}

fn fieldSet(fields: *PackedFields, index: usize, value: i32) void {
    const word_index = index / 9;
    const shift: u6 = @intCast((index % 9) * 7);
    const mask = @as(u64, 127) << shift;
    const encoded: u64 = if (value < 0) 127 else @intCast(value);
    fields.word[word_index] = (fields.word[word_index] & ~mask) | (encoded << shift);
}

fn listGet(list: [*]const u64, index: usize) usize {
    const word_index = index / 10;
    const shift: u6 = @intCast((index % 10) * 6);
    return @intCast((list[word_index] >> shift) & 63);
}

fn listSet(list: [*]u64, index: usize, value: usize) void {
    const word_index = index / 10;
    const shift: u6 = @intCast((index % 10) * 6);
    const mask = @as(u64, 63) << shift;
    list[word_index] = (list[word_index] & ~mask) | (@as(u64, @intCast(value)) << shift);
}

fn bitIsSet(bits: u64, index: usize) bool {
    return ((bits >> @intCast(index)) & 1) != 0;
}

fn bitsBelow(bits: u64, index: usize) usize {
    const mask: u64 = if (index == 0) 0 else (@as(u64, 1) << @intCast(index)) - 1;
    return @intCast(@popCount(bits & mask));
}

fn symbolAt(input: InputView, index: usize) i32 {
    if (!input.is_packed) {
        if (index == input.raw_length) return 0;
        return @intCast(input.raw[index + input.raw_offset] + 1);
    }
    return @intCast(listGet(input.packed, index));
}

fn saGet(output: [*]const u8, index: usize) i64 {
    var bits: u64 = 0;
    const offset = index * 8;
    for (0..8) |byte| bits |= @as(u64, output[offset + byte]) << @intCast(byte * 8);
    const value: i64 = @bitCast(bits);
    return if (value < 0) -1 else value;
}

fn saSet(output: [*]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    const offset = index * 8;
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn buildBuckets(input: InputView, length: usize, upper: usize,
                types: u64, heads: *PackedFields, tails: *PackedFields,
                s_starts: *PackedFields) void {
    var counts = PackedFields{};
    var l_counts = PackedFields{};
    var prefix: i32 = 0;
    for (0..length) |index| {
        const symbol: usize = @intCast(symbolAt(input, index));
        fieldSet(&counts, symbol, fieldGet(&counts, symbol) + 1);
        if (!bitIsSet(types, index)) fieldSet(&l_counts, symbol, fieldGet(&l_counts, symbol) + 1);
    }
    for (0..(upper + 1)) |symbol| {
        const count = fieldGet(&counts, symbol);
        fieldSet(heads, symbol, prefix);
        fieldSet(tails, symbol, prefix + count - 1);
        fieldSet(s_starts, symbol, prefix + fieldGet(&l_counts, symbol));
        prefix += count;
    }
}

fn sameLmsSubstring(input: InputView, length: usize, types: u64, lms: u64,
                    left: usize, right: usize) bool {
    if (left == right) return true;
    for (0..length) |offset| {
        const a = left + offset;
        const b = right + offset;
        if (a >= length or b >= length or symbolAt(input, a) != symbolAt(input, b) or
            bitIsSet(types, a) != bitIsSet(types, b)) return false;
        if (offset > 0 and (bitIsSet(lms, a) or bitIsSet(lms, b)))
            return bitIsSet(lms, a) and bitIsSet(lms, b);
    }
    return false;
}

fn induce(input: InputView, length: usize, upper: usize, types: u64, lms: u64,
          seeds: [*]const u64, seed_count: usize, use_lms_mask: bool,
          output: [*]u8) void {
    var heads = PackedFields{};
    var tails = PackedFields{};
    var s_starts = PackedFields{};
    var l_cursor = PackedFields{};
    var s_cursor = PackedFields{};
    buildBuckets(input, length, upper, types, &heads, &tails, &s_starts);
    for (0..length) |index| saSet(output, index, -1);
    for (0..(upper + 1)) |symbol| fieldSet(&s_cursor, symbol, fieldGet(&s_starts, symbol));
    if (use_lms_mask) {
        for (0..length) |position| {
            if (!bitIsSet(lms, position)) continue;
            const symbol: usize = @intCast(symbolAt(input, position));
            const slot: usize = @intCast(fieldGet(&s_cursor, symbol));
            saSet(output, slot, @intCast(position));
            fieldSet(&s_cursor, symbol, @as(i32, @intCast(slot)) + 1);
        }
    } else {
        for (0..seed_count) |item| {
            const position = listGet(seeds, item);
            const symbol: usize = @intCast(symbolAt(input, position));
            const slot: usize = @intCast(fieldGet(&s_cursor, symbol));
            saSet(output, slot, @intCast(position));
            fieldSet(&s_cursor, symbol, @as(i32, @intCast(slot)) + 1);
        }
    }
    for (0..(upper + 1)) |symbol| {
        fieldSet(&l_cursor, symbol, fieldGet(&heads, symbol));
        fieldSet(&s_cursor, symbol, fieldGet(&tails, symbol) + 1);
    }
    for (0..length) |slot| {
        const position = saGet(output, slot);
        if (position <= 0) continue;
        const previous: usize = @intCast(position - 1);
        if (bitIsSet(types, previous)) continue;
        const symbol: usize = @intCast(symbolAt(input, previous));
        const target: usize = @intCast(fieldGet(&l_cursor, symbol));
        saSet(output, target, @intCast(previous));
        fieldSet(&l_cursor, symbol, @as(i32, @intCast(target)) + 1);
    }
    var slot = length;
    while (slot > 0) {
        slot -= 1;
        const position = saGet(output, slot);
        if (position <= 0) continue;
        const previous: usize = @intCast(position - 1);
        if (!bitIsSet(types, previous)) continue;
        const symbol: usize = @intCast(symbolAt(input, previous));
        const target = fieldGet(&s_cursor, symbol) - 1;
        saSet(output, @intCast(target), @intCast(previous));
        fieldSet(&s_cursor, symbol, target);
    }
}

fn saisReadonly(input: InputView, length: usize, upper: usize, output: [*]u8) void {
    if (length == 0) return;
    if (length == 1) { saSet(output, 0, 0); return; }
    if (length == 2) {
        if (symbolAt(input, 0) >= symbolAt(input, 1)) {
            saSet(output, 0, 1);
            saSet(output, 1, 0);
        } else {
            saSet(output, 0, 0);
            saSet(output, 1, 1);
        }
        return;
    }
    var types = @as(u64, 1) << @intCast(length - 1);
    var index = length - 1;
    while (index > 0) {
        index -= 1;
        const current = symbolAt(input, index);
        const next = symbolAt(input, index + 1);
        if (current < next or (current == next and bitIsSet(types, index + 1)))
            types |= @as(u64, 1) << @intCast(index);
    }
    var lms: u64 = 0;
    var lms_positions = [_]u64{0} ** PACKED_LIST_WORDS;
    var lms_count: usize = 0;
    for (1..length) |position| {
        if (!bitIsSet(types, position - 1) and bitIsSet(types, position)) {
            lms |= @as(u64, 1) << @intCast(position);
            listSet(&lms_positions, lms_count, position);
            lms_count += 1;
        }
    }
    const empty_seeds = [_]u64{0} ** PACKED_LIST_WORDS;
    induce(input, length, upper, types, lms, &empty_seeds, 0, true, output);
    var reduced = [_]u64{0} ** PACKED_LIST_WORDS;
    var name: usize = 0;
    var sorted_count: usize = 0;
    var previous_lms: ?usize = null;
    for (0..length) |slot| {
        const candidate = saGet(output, slot);
        if (candidate < 0 or !bitIsSet(lms, @intCast(candidate))) continue;
        const position: usize = @intCast(candidate);
        if (previous_lms) |previous| {
            if (!sameLmsSubstring(input, length, types, lms, previous, position)) name += 1;
        }
        listSet(&reduced, bitsBelow(lms, position), name);
        previous_lms = position;
        sorted_count += 1;
    }
    if (sorted_count != lms_count) return;
    if (name + 1 == lms_count) {
        for (0..lms_count) |ordinal|
            saSet(output, listGet(&reduced, ordinal), @intCast(ordinal));
    } else {
        const reduced_input = InputView{ .raw = undefined, .packed = &reduced, .raw_length = 0, .raw_offset = 0, .is_packed = true };
        saisReadonly(reduced_input, lms_count, name, output);
    }
    var ordered_lms = [_]u64{0} ** PACKED_LIST_WORDS;
    for (0..lms_count) |item| {
        const ordinal: usize = @intCast(saGet(output, item));
        listSet(&ordered_lms, item, listGet(&lms_positions, ordinal));
    }
    induce(input, length, upper, types, lms, &ordered_lms, lms_count, false, output);
}

export fn suffix_array_inplace_readonly_integer(values: [*c]const i64,
    length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (0..count) |index| if (values[index + 1] < 0 or values[index + 1] >= @as(i64, @intCast(count))) return -1;
    const workspace_bytes = (count + 1) * 8;
    const output_bytes = count * 8;
    if (output == null or capacity < workspace_bytes) return -2;
    const input = InputView{ .raw = @ptrCast(values + 1), .packed = undefined, .raw_length = count, .raw_offset = 0, .is_packed = false };
    saisReadonly(input, count + 1, count, @ptrCast(output));
    for (0..count) |index| {
        const position = saGet(@ptrCast(output), index + 1);
        saSet(@ptrCast(output), index, position);
    }
    return @intCast(output_bytes);
}
