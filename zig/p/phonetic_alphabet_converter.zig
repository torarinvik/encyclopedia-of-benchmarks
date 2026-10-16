const words = [_][]const u8{ "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu", "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" };
export fn phonetic_alphabet_converter(v: [*]const i64, n: usize, out: [*]u8, cap: usize) i64 {
    if (n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    if (cap < 576) return -2;
    var at: usize = 0;
    var emitted = false;
    for (0..@intCast(v[0])) |i| {
        const raw = v[i + 1];
        if (!((raw == 9 or raw == 10 or raw == 11 or raw == 12 or raw == 13 or raw == 32) or (raw >= 33 and raw <= 126))) return -1;
        if (raw == 9 or raw == 10 or raw == 11 or raw == 12 or raw == 13 or raw == 32) continue;
        var c: u8 = @intCast(raw);
        if (c >= 'a' and c <= 'z') c -= 32;
        if (emitted) { out[at] = ' '; at += 1; }
        emitted = true;
        if (c >= 'A' and c <= 'Z') {
            const word = words[c - 'A']; for (word) |b| { out[at] = b; at += 1; }
        } else if (c >= '0' and c <= '9') {
            const word = words[26 + c - '0']; for (word) |b| { out[at] = b; at += 1; }
        } else { out[at] = c; at += 1; }
    }
    return @intCast(at);
}
