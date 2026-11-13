const N: usize = 8;
const L: usize = 8;
const H: usize = 17;

fn isPalindrome(words: *const [64]i32, id: usize, left: usize, right: usize) bool {
    var lo = left;
    if (right == 0) return true;
    var hi = right - 1;
    while (lo < hi) : (lo += 1) {
        if (words[id * L + lo] != words[id * L + hi]) return false;
        hi -= 1;
    }
    return true;
}

fn encode(words: *const [64]i32, id: usize, left: usize, right: usize, reverse: bool) i64 {
    var key: i64 = 1;
    if (reverse) {
        var i = right;
        while (i > left) {
            i -= 1;
            key = key * 5 + @as(i64, words[id * L + i]) + 1;
        }
    } else {
        for (left..right) |i| key = key * 5 + @as(i64, words[id * L + i]) + 1;
    }
    return key;
}

fn findSlot(keys: *const [H]i64, key: i64) usize {
    var slot: usize = @intCast(@mod(key, @as(i64, H)));
    while (keys[slot] != 0 and keys[slot] != key) slot = (slot + 1) % H;
    return slot;
}

fn mark(keys: *const [H]i64, heads: *const [H]i32, next: *const [N]i32,
        key: i64, fixed: usize, fixed_right: bool, found: *[64]bool) void {
    const slot = findSlot(keys, key);
    if (keys[slot] != key) return;
    var id = heads[slot];
    while (id >= 0) {
        const word: usize = @intCast(id);
        if (word != fixed) {
            if (fixed_right) found[word * N + fixed] = true
            else found[fixed * N + word] = true;
        }
        id = next[word];
    }
}

export fn palindrome_pairs(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 74 or input[0] < 0 or input[0] > @as(i64, N)) return -1;
    const count: usize = @intCast(input[0]);
    var words = [_]i32{0} ** (N * L);
    var sizes = [_]usize{0} ** N;
    var cursor: usize = 1;
    for (0..count) |id| {
        if (cursor >= length or input[cursor] < 0 or input[cursor] > @as(i64, L)) return -1;
        const size: usize = @intCast(input[cursor]);
        cursor += 1;
        if (cursor + size > length) return -1;
        sizes[id] = size;
        for (0..size) |k| {
            if (input[cursor] < 0 or input[cursor] >= 4) return -1;
            words[id * L + k] = @intCast(input[cursor]);
            cursor += 1;
        }
    }
    if (cursor != length) return -1;
    var keys = [_]i64{0} ** H;
    var heads = [_]i32{-1} ** H;
    var next = [_]i32{-1} ** N;
    for (0..count) |id| {
        const key = encode(&words, id, 0, sizes[id], false);
        const slot = findSlot(&keys, key);
        if (keys[slot] == 0) {
            keys[slot] = key;
            heads[slot] = @intCast(id);
        } else {
            next[id] = heads[slot];
            heads[slot] = @intCast(id);
        }
    }
    var found = [_]bool{false} ** (N * N);
    for (0..count) |id| {
        for (0..(sizes[id] + 1)) |split| {
            if (isPalindrome(&words, id, 0, split)) mark(&keys, &heads, &next, encode(&words, id, split, sizes[id], true), id, true, &found);
            if (isPalindrome(&words, id, split, sizes[id])) mark(&keys, &heads, &next, encode(&words, id, 0, split, true), id, false, &found);
        }
    }
    var staged = [_]u8{0} ** (N * (N - 1));
    var bytes: usize = 0;
    for (0..count) |left| {
        for (0..count) |right| {
            if (left != right and found[left * N + right]) {
                staged[bytes] = @intCast(left * N + right);
                bytes += 1;
            }
        }
    }
    if (output == null or capacity < bytes) return -2;
    for (0..bytes) |i| output[i] = staged[i];
    return @intCast(bytes);
}
