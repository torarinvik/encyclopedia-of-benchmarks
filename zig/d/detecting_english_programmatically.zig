export fn detecting_english_programmatically(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 172) return -1;
    var p: usize = 0;
    const count = input[p]; p += 1;
    if (count < 0 or count > 8) return -1;
    var starts: [8]usize = undefined; var lens: [8]usize = undefined;
    for (0..@intCast(count)) |w| {
        if (p >= length) return -1; const l = input[p]; p += 1;
        if (l < 1 or l > 12 or p + @as(usize, @intCast(l)) > length) return -1;
        starts[w] = p; lens[w] = @intCast(l);
        for (0..lens[w]) |j| if (input[p+j] < 65 or input[p+j] > 90) { return -1; };
        if (w > 0) {
            var k: usize = 0;
            while (k < lens[w-1] and k < lens[w] and input[starts[w-1]+k] == input[p+k]) : (k += 1) {}
            if (k == lens[w-1] and k == lens[w]) return -1;
            if (k == lens[w-1] and k < lens[w]) {} else if (k < lens[w-1] and k < lens[w] and input[starts[w-1]+k] > input[p+k]) return -1 else if (k < lens[w-1] and k == lens[w]) return -1;
        }
        p += @intCast(l);
    }
    if (p >= length) return -1; const m = input[p]; p += 1;
    if (m < 1 or m > 64 or p + @as(usize, @intCast(m)) + 2 != length) return -1;
    const ms = p; const msg_len: usize = @intCast(m);
    for (0..msg_len) |j| if (input[ms+j] < 0 or input[ms+j] > 127) { return -1; };
    p += msg_len; const wp = input[p]; const lp = input[p+1];
    if (wp < 0 or wp > 100 or lp < 0 or lp > 100) return -1;
    var retained: i64 = 0; var tokens: i64 = 0; var hits: i64 = 0; var i: usize = 0; var token: [64]i64 = undefined; var tlen: usize = 0;
    while (i <= msg_len) {
        const c: i64 = if (i < msg_len) input[ms+i] else 32; const letter = (c >= 65 and c <= 90) or (c >= 97 and c <= 122); const ws = c == 9 or c == 10 or c == 32;
        if (i < msg_len and (letter or ws)) retained += 1;
        if (letter) { token[tlen] = if (c >= 97) c - 32 else c; tlen += 1; i += 1; continue; }
        if (!ws) { i += 1; continue; }
        if (tlen == 0) { i += 1; continue; }
        tokens += 1;
        for (0..@intCast(count)) |w| {
            if (lens[w] != tlen) continue; var k: usize = 0;
            while (k < tlen and input[starts[w]+k] == token[k]) : (k += 1) {}
            if (k == tlen) { hits += 1; break; }
        }
        tlen = 0; i += 1;
    }
    if (tokens == 0) return -1;
    return @intFromBool(hits * 100 >= wp * tokens and retained * 100 >= lp * m);
}
