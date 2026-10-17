const std = @import("std");

const MAX_OPERATIONS: usize = 64;
const MAX_WORD_LENGTH: usize = 32;
const MAX_WORDS: usize = 32;
const MAX_NODES: usize = 1 + MAX_WORDS * MAX_WORD_LENGTH;
const MAX_VALID_INPUT_LENGTH: usize = 2177;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2178;
const FNV_OFFSET: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;

const Node = struct {
    children: [26]usize = @splat(0),
    word_index_plus_one: usize = 0,
};

const Word = struct {
    bytes: [MAX_WORD_LENGTH]u8 = @splat(0),
    length: usize = 0,
    frequency: u32 = 0,
};

fn hashByte(hash_value: u64, byte: u8) u64 {
    return (hash_value ^ byte) *% FNV_PRIME;
}

fn hashU16(hash_value: u64, value: u16) u64 {
    var hash = hash_value;
    for (0..2) |shift| hash = hashByte(hash, @truncate(value >> @intCast(shift * 8)));
    return hash;
}

fn hashU32(hash_value: u64, value: u32) u64 {
    var hash = hash_value;
    for (0..4) |shift| hash = hashByte(hash, @truncate(value >> @intCast(shift * 8)));
    return hash;
}

fn wordLess(words: *const [MAX_WORDS]Word, left: usize, right: usize) bool {
    const a = words[left];
    const b = words[right];
    const common = @min(a.length, b.length);
    for (0..common) |index| {
        if (a.bytes[index] != b.bytes[index]) return a.bytes[index] < b.bytes[index];
    }
    return a.length < b.length;
}

export fn trie_multiple_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (length > MAX_VALID_INPUT_LENGTH or input[0] < 0 or input[0] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const operation_count: usize = @intCast(input[0]);
    var nodes: [MAX_NODES]Node = @splat(.{});
    var node_count: usize = 1;
    var words: [MAX_WORDS]Word = @splat(.{});
    var word_count: usize = 0;
    var hash: u64 = hashU16(FNV_OFFSET, @intCast(operation_count));
    var offset: usize = 1;

    for (0..operation_count) |_| {
        if (offset + 2 > length) return -1;
        const opcode_value = input[offset];
        const word_length_value = input[offset + 1];
        offset += 2;
        if (opcode_value < 0 or opcode_value > 3 or word_length_value < 0 or word_length_value > @as(i64, @intCast(MAX_WORD_LENGTH))) return -1;
        const opcode: u8 = @intCast(opcode_value);
        const word_length: usize = @intCast(word_length_value);
        if (opcode == 0 and word_length == 0) return -1;
        if (offset + word_length > length) return -1;
        var raw: [MAX_WORD_LENGTH]u8 = @splat(0);
        var folded: [MAX_WORD_LENGTH]u8 = @splat(0);
        for (0..word_length) |index| {
            const byte = input[offset + index];
            if (byte >= 65 and byte <= 90) {
                raw[index] = @intCast(byte);
                folded[index] = @intCast(byte + 32);
            } else if (byte >= 97 and byte <= 122) {
                raw[index] = @intCast(byte);
                folded[index] = @intCast(byte);
            } else return -1;
        }
        offset += word_length;
        hash = hashByte(hash, opcode);

        var node: usize = 0;
        var matched: usize = 0;
        for (0..word_length) |index| {
            const letter: usize = @intCast(folded[index] - 'a');
            const child = nodes[node].children[letter];
            if (child == 0) break;
            node = child;
            matched += 1;
        }
        if (opcode == 0) {
            var insert_node: usize = 0;
            for (0..word_length) |index| {
                const letter: usize = @intCast(folded[index] - 'a');
                var child = nodes[insert_node].children[letter];
                if (child == 0) {
                    if (node_count >= MAX_NODES) return -1;
                    child = node_count;
                    node_count += 1;
                    nodes[insert_node].children[letter] = child;
                }
                insert_node = child;
            }
            if (nodes[insert_node].word_index_plus_one == 0) {
                if (word_count >= MAX_WORDS) return -1;
                words[word_count].bytes = folded;
                words[word_count].length = word_length;
                nodes[insert_node].word_index_plus_one = word_count + 1;
                word_count += 1;
            }
            continue;
        }

        var exact_index: ?usize = null;
        if (matched == word_length and nodes[node].word_index_plus_one != 0) {
            exact_index = nodes[node].word_index_plus_one - 1;
        }
        if (opcode == 1) {
            const present = exact_index != null;
            if (exact_index) |index| words[index].frequency += 1;
            hash = hashByte(hash, @intCast(@intFromBool(present)));
            continue;
        }

        var suggestions: [MAX_WORDS]usize = @splat(0);
        var suggestion_count: usize = 0;
        for (0..word_count) |word_index| {
            const word = words[word_index];
            if (word.length > matched and std.mem.eql(u8, word.bytes[0..matched], folded[0..matched])) {
                suggestions[suggestion_count] = word_index;
                suggestion_count += 1;
            }
        }
        if (exact_index) |index| words[index].frequency += 1;
        for (1..suggestion_count) |i| {
            const current = suggestions[i];
            var j = i;
            while (j > 0) {
                const previous = suggestions[j - 1];
                const before = if (opcode == 2)
                    wordLess(&words, current, previous)
                else
                    words[current].frequency > words[previous].frequency or
                        (words[current].frequency == words[previous].frequency and wordLess(&words, previous, current));
                if (!before) break;
                suggestions[j] = previous;
                j -= 1;
            }
            suggestions[j] = current;
        }
        const limit = if (opcode == 2) suggestion_count else @min(suggestion_count, 3);
        const exact_count: usize = if (exact_index != null) 1 else 0;
        hash = hashU16(hash, @intCast(limit + exact_count));
        if (exact_index != null) {
            hash = hashByte(hash, @intCast(word_length));
            for (0..word_length) |index| hash = hashByte(hash, raw[index]);
        }
        for (0..limit) |i| {
            const word = words[suggestions[i]];
            hash = hashByte(hash, @intCast(word.length));
            for (0..word.length) |index| hash = hashByte(hash, word.bytes[index]);
        }
    }
    if (offset != length) return -1;
    hash = hashU16(hash, @intCast(word_count));
    var order: [MAX_WORDS]usize = @splat(0);
    for (0..word_count) |index| order[index] = index;
    for (1..word_count) |i| {
        const current = order[i];
        var j = i;
        while (j > 0 and wordLess(&words, current, order[j - 1])) : (j -= 1) {
            order[j] = order[j - 1];
        }
        order[j] = current;
    }
    for (0..word_count) |i| {
        const word = words[order[i]];
        hash = hashByte(hash, @intCast(word.length));
        for (0..word.length) |index| hash = hashByte(hash, word.bytes[index]);
        hash = hashU32(hash, word.frequency);
    }
    return @intCast(hash & 0x7fffffffffffffff);
}
