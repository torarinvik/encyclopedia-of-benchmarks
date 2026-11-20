/// 64-ary hierarchical bitmap predecessor set.
fn wary_low_bit(bits: u64) usize {
    var low: usize = 0;
    var high: usize = 64;
    while (high - low > 1) {
        const middle = (low + high) / 2;
        const mask = (@as(u64, 1) << @intCast(middle)) - 1;
        if (bits & mask != 0) high = middle else low = middle;
    }
    return low;
}

fn wary_high_bit(bits: u64) usize {
    var low: usize = 0;
    var high: usize = 64;
    while (high - low > 1) {
        const middle = (low + high) / 2;
        if (bits >> @intCast(middle) != 0) low = middle else high = middle;
    }
    return low;
}

const WarySet = struct {
    leaf: [4096]u64 = @splat(0),
    group: [64]u64 = @splat(0),
    top: u64 = 0,

    fn insert(self: *WarySet, key: usize) i64 {
        const word = key >> 6;
        const bit_index = key & 63;
        const bit = @as(u64, 1) << @intCast(bit_index);
        const old = self.leaf[word];
        if (old & bit != 0) return 0;
        if (old == 0) {
            const group_index = word >> 6;
            const slot = word & 63;
            if (self.group[group_index] == 0) self.top |= @as(u64, 1) << @intCast(group_index);
            self.group[group_index] |= @as(u64, 1) << @intCast(slot);
        }
        self.leaf[word] = old | bit;
        return 1;
    }

    fn erase(self: *WarySet, key: usize) i64 {
        const word = key >> 6;
        const bit_index = key & 63;
        const bit = @as(u64, 1) << @intCast(bit_index);
        const old = self.leaf[word];
        if (old & bit == 0) return 0;
        self.leaf[word] = old & ~bit;
        if (self.leaf[word] == 0) {
            const group_index = word >> 6;
            const slot = word & 63;
            self.group[group_index] &= ~(@as(u64, 1) << @intCast(slot));
            if (self.group[group_index] == 0) self.top &= ~(@as(u64, 1) << @intCast(group_index));
        }
        return 1;
    }

    fn contains(self: *const WarySet, key: usize) i64 {
        return if (self.leaf[key >> 6] & (@as(u64, 1) << @intCast(key & 63)) != 0) 1 else 0;
    }

    fn successor(self: *const WarySet, key: usize) i64 {
        const word = key >> 6;
        const bit_index = key & 63;
        const candidates = self.leaf[word] >> @intCast(bit_index);
        if (candidates != 0) return @intCast(word * 64 + bit_index + wary_low_bit(candidates) + 1);
        const group_index = word >> 6;
        const slot = word & 63;
        var later: u64 = 0;
        if (slot < 63) later = self.group[group_index] >> @intCast(slot + 1);
        var next_word: usize = 0;
        if (later != 0) {
            next_word = group_index * 64 + slot + 1 + wary_low_bit(later);
        } else {
            if (group_index < 63) later = self.top >> @intCast(group_index + 1) else later = 0;
            if (later == 0) return 0;
            const next_group = group_index + 1 + wary_low_bit(later);
            next_word = next_group * 64 + wary_low_bit(self.group[next_group]);
        }
        return @intCast(next_word * 64 + wary_low_bit(self.leaf[next_word]) + 1);
    }

    fn predecessor(self: *const WarySet, key: usize) i64 {
        const word = key >> 6;
        const bit_index = key & 63;
        const candidates = self.leaf[word] & ((@as(u64, 1) << @intCast(bit_index)) - 1);
        if (candidates != 0) return @intCast(word * 64 + wary_high_bit(candidates) + 1);
        const group_index = word >> 6;
        const slot = word & 63;
        var earlier = self.group[group_index] & ((@as(u64, 1) << @intCast(slot)) - 1);
        var previous_word: usize = 0;
        if (earlier != 0) {
            previous_word = group_index * 64 + wary_high_bit(earlier);
        } else {
            earlier = self.top & ((@as(u64, 1) << @intCast(group_index)) - 1);
            if (earlier == 0) return 0;
            const previous_group = wary_high_bit(earlier);
            previous_word = previous_group * 64 + wary_high_bit(self.group[previous_group]);
        }
        return @intCast(previous_word * 64 + wary_high_bit(self.leaf[previous_word]) + 1);
    }
};

export fn w_ary_predecessor_set(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 66) return -1;
    if (input[0] < 0 or input[0] > 32) return -1;
    const q: usize = @intCast(input[0]);
    if (length != 1 + 2 * q) return -1;
    var state = WarySet{};
    var result: i64 = 0;
    var cursor: usize = 1;
    for (0..q) |operation| {
        const opcode = input[cursor];
        const raw_key = input[cursor + 1];
        cursor += 2;
        if (opcode < 0 or opcode > 4 or raw_key < 0 or raw_key >= 262144) return -1;
        const key: usize = @intCast(raw_key);
        const answer = switch (opcode) {
            0 => state.insert(key),
            1 => state.erase(key),
            2 => state.contains(key),
            3 => state.successor(key),
            else => state.predecessor(key),
        };
        result += @as(i64, @intCast(operation + 1)) * answer;
    }
    return result;
}
