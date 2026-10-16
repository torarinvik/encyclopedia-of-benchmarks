/// Return English frequency match score for a bounded ASCII byte string.
export fn frequency_finder(input: [*c]const i64, length: usize) i64 {
    const etaoin = "ETAOINSHRDLCUMWFGYPBVKJXQZ";
    if (input == null) return if (length == 0) 0 else -1;
    if (length > 1024) return -1;
    var counts = [_]i64{0} ** 26;
    for (0..length) |i| {
        var b = input[i];
        if (b < 0 or b > 127) return -1;
        if (b >= 97 and b <= 122) b -= 32;
        if (b >= 65 and b <= 90) counts[@intCast(b - 65)] += 1;
    }
    var order: [26]usize = undefined;
    for (0..26) |i| order[i] = i;
    for (1..26) |i| {
        const key = order[i]; var j = i;
        const kr = std.mem.indexOfScalar(u8, etaoin, @intCast(65 + key)).?;
        while (j > 0) {
            const p = order[j - 1];
            const pr = std.mem.indexOfScalar(u8, etaoin, @intCast(65 + p)).?;
            if (counts[p] > counts[key] or (counts[p] == counts[key] and pr > kr)) break;
            order[j] = p; j -= 1;
        }
        order[j] = key;
    }
    var score: i64 = 0;
    for (0..6) |i| {
        const high_letter: u8 = @intCast(65 + order[i]);
        const low_letter: u8 = @intCast(65 + order[20 + i]);
        if (std.mem.indexOfScalar(u8, etaoin[0..6], high_letter) != null) score += 1;
        if (std.mem.indexOfScalar(u8, etaoin[20..26], low_letter) != null) score += 1;
    }
    return score;
}

const std = @import("std");
