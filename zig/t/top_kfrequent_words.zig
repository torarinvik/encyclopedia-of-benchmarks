const MAX_WORDS = 64;
const MAX_WORD_LENGTH = 16;

fn sift(heap: *[MAX_WORDS]usize, counts: *const [MAX_WORDS]usize, size: usize, root: usize) void {
    var best = root;
    const left = root * 2 + 1;
    const right = left + 1;
    if (left < size and counts[heap[left]] > counts[heap[best]]) best = left;
    if (right < size and counts[heap[right]] > counts[heap[best]]) best = right;
    if (best != root) { const tmp = heap[root]; heap[root] = heap[best]; heap[best] = tmp; sift(heap, counts, size, best); }
}

export fn top_kfrequent_words(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > 1090) return -1;
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 64) return -1;
    const k: usize = @intCast(values[0]); const word_count: usize = @intCast(values[1]);
    var words: [MAX_WORDS][MAX_WORD_LENGTH]u8 = @splat(@splat(0));
    var lens: [MAX_WORDS]usize = @splat(0); var counts: [MAX_WORDS]usize = @splat(0);
    var heap: [MAX_WORDS]usize = @splat(0); var distinct: usize = 0; var pos: usize = 2;
    for (0..word_count) |_| {
        if (pos >= length or values[pos] < 1 or values[pos] > MAX_WORD_LENGTH) return -1;
        const word_len: usize = @intCast(values[pos]); pos += 1;
        if (word_len > length - pos) return -1;
        for (0..word_len) |j| if (values[pos+j] < 'a' or values[pos+j] > 'z') return -1;
        var id: usize = 0;
        while (id < distinct) : (id += 1) {
            if (lens[id] == word_len) {
                var j: usize = 0; while (j < word_len and words[id][j] == values[pos+j]) : (j += 1) {}
                if (j == word_len) break;
            }
        }
        if (id == distinct) { lens[id] = word_len; for (0..word_len) |j| words[id][j] = @intCast(values[pos+j]); distinct += 1; }
        counts[id] += 1; pos += word_len;
    }
    if (pos != length) return -1;
    for (0..distinct) |id| {
        var rank: usize = 0;
        for (0..distinct) |other| {
            const common = @min(lens[id], lens[other]);
            var j: usize = 0; while (j < common and words[other][j] == words[id][j]) : (j += 1) {}
            if ((j < common and words[other][j] < words[id][j]) or (j == common and lens[other] < lens[id])) rank += 1;
        }
        counts[id] = counts[id] * 65 + distinct - rank;
    }
    for (0..distinct) |i| heap[i] = i;
    var build = distinct / 2; while (build > 0) { build -= 1; sift(&heap, &counts, distinct, build); }
    const limit = @min(k, distinct); var temp: [MAX_WORDS * (MAX_WORD_LENGTH + 1) + 1]u8 = undefined; var at: usize = 0;
    for (0..limit) |_| {
        const id = heap[0]; @memcpy(temp[at..][0..lens[id]], words[id][0..lens[id]]); at += lens[id]; temp[at] = '\n'; at += 1;
        distinct -= 1; heap[0] = heap[distinct]; if (distinct > 0) sift(&heap, &counts, distinct, 0);
    }
    temp[at] = 0; at += 1; if (output == null or capacity < at) return -2;
    @memcpy(output[0..at], temp[0..at]); return @intCast(at);
}

