const std = @import("std");
const MAX_TEXT: usize = 32;
const MAX_DICT: usize = MAX_TEXT + 1;
const MAX_OUTPUT: usize = 16 * MAX_TEXT;
const Words = [MAX_DICT][MAX_TEXT]u8;
const Lengths = [MAX_DICT]usize;

fn putU64(out: *[MAX_OUTPUT]u8, offset: usize, value: u64) void {
    for (0..8) |i| out[offset + i] = @truncate(value >> @as(u6, @intCast(i * 8)));
}
fn wordMatches(words: *const Words, lengths: *const Lengths, id: usize,
    text: *const [MAX_TEXT]u8, n: usize, pos: usize) bool {
    const len = lengths.*[id];
    return pos + len <= n and std.mem.eql(u8, words.*[id][0..len], text.*[pos..pos + len]);
}
fn findWord(words: *const Words, lengths: *const Lengths, count: usize,
    phrase: *const [MAX_TEXT]u8, len: usize) usize {
    for (1..count) |id| {
        if (lengths.*[id] == len and std.mem.eql(u8, words.*[id][0..len], phrase.*[0..len])) return id;
    }
    return count;
}
fn longestMatch(words: *const Words, lengths: *const Lengths, count: usize,
    extra: *const [MAX_TEXT]u8, extraLen: usize, hasExtra: bool,
    text: *const [MAX_TEXT]u8, n: usize, pos: usize) usize {
    var best: usize = 0;
    for (1..count) |id| {
        if (lengths.*[id] > best and wordMatches(words, lengths, id, text, n, pos)) best = lengths.*[id];
    }
    if (hasExtra and extraLen > best and pos + extraLen <= n and
        std.mem.eql(u8, extra.*[0..extraLen], text.*[pos..pos + extraLen])) best = extraLen;
    return best;
}

export fn lz78_flexible_parsing(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > 34) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT) return -1;
    const n: usize = @intCast(input[0]);
    if (input_length != n + 1) return -1;
    var text = [_]u8{0} ** MAX_TEXT;
    for (0..n) |i| {
        if (input[i + 1] < 32 or input[i + 1] > 126) return -1;
        text[i] = @intCast(input[i + 1]);
    }
    var words = [_][MAX_TEXT]u8{[_]u8{0} ** MAX_TEXT} ** MAX_DICT;
    var lengths = [_]usize{0} ** MAX_DICT;
    var parents = [_]i64{0} ** MAX_TEXT;
    var symbols = [_]i64{0} ** MAX_TEXT;
    var count: usize = 1;
    var tokenCount: usize = 0;
    var pos: usize = 0;
    while (pos < n) {
        var finalId = count;
        for (1..count) |id| {
            if (lengths[id] == n - pos and std.mem.eql(u8, words[id][0..n - pos], text[pos..n])) { finalId = id; break; }
        }
        if (finalId != count) {
            parents[tokenCount] = @intCast(finalId); symbols[tokenCount] = 0; tokenCount += 1; pos = n; break;
        }
        var have = false;
        var bestParent: usize = 0;
        var bestLen: usize = 0;
        var bestNext: usize = 0;
        var bestSymbol: u8 = 0;
        var bestNew = false;
        var bestWord = [_]u8{0} ** MAX_TEXT;
        for (0..count) |parent| {
            if (!wordMatches(&words, &lengths, parent, &text, n, pos)) continue;
            const prefixLen = lengths[parent];
            const symbolPos = pos + prefixLen;
            if (symbolPos >= n) continue;
            const phraseLen = prefixLen + 1;
            var phrase = [_]u8{0} ** MAX_TEXT;
            @memcpy(phrase[0..prefixLen], words[parent][0..prefixLen]);
            phrase[prefixLen] = text[symbolPos];
            const isNew = findWord(&words, &lengths, count, &phrase, phraseLen) == count;
            const nextPos = pos + phraseLen;
            const nextMatch = longestMatch(&words, &lengths, count, &phrase, phraseLen, isNew, &text, n, nextPos);
            const advancement = phraseLen + nextMatch;
            if (!have or advancement > bestNext or (advancement == bestNext and phraseLen > bestLen) or
                (advancement == bestNext and phraseLen == bestLen and parent < bestParent)) {
                have = true; bestParent = parent; bestLen = phraseLen; bestNext = advancement;
                bestSymbol = text[symbolPos]; bestNew = isNew; bestWord = phrase;
            }
        }
        if (!have) return -1;
        parents[tokenCount] = @intCast(bestParent); symbols[tokenCount] = bestSymbol; tokenCount += 1;
        if (bestNew) { words[count] = bestWord; lengths[count] = bestLen; count += 1; }
        pos += bestLen;
    }
    const outputBytes = tokenCount * 16;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    for (0..tokenCount) |i| {
        putU64(&staged, 16 * i, @bitCast(parents[i]));
        putU64(&staged, 16 * i + 8, @bitCast(symbols[i]));
    }
    if (output == null or capacity < outputBytes) return -2;
    if (outputBytes > 0) @memcpy(output[0..outputBytes], staged[0..outputBytes]);
    return @intCast(outputBytes);
}
