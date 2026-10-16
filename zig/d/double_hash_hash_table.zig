/// Run bounded insert (1), search (2), and delete (3) operations using double hashing.
export fn double_hash_hash_table(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const cap64 = input[0];
    const count64 = input[1];
    if (cap64 < 3 or cap64 > 101 or count64 < 0 or count64 > 512) return -1;
    const cap: usize = @intCast(cap64);
    const count: usize = @intCast(count64);
    if (length != 2 + 2 * count) return -1;
    var d: usize = 2;
    while (d * d <= cap) : (d += 1) if (cap % d == 0) return -1;
    var states: [101]u8 = @splat(0);
    var keys: [101]i64 = @splat(0);
    var successes: i64 = 0;
    for (0..count) |i| {
        const op = input[2 + 2 * i];
        const key = input[3 + 2 * i];
        if (op < 1 or op > 3) return -1;
        const first: usize = @intCast(@mod(key, cap64));
        const step: usize = 1 + @as(usize, @intCast(@mod(key, cap64 - 1)));
        if (op == 1) {
            var tomb = cap;
            var inserted = false;
            for (0..cap) |p| {
                const slot = (first + p * step) % cap;
                if (states[slot] == 1 and keys[slot] == key) { tomb = cap; break; }
                if (states[slot] == 2 and tomb == cap) tomb = slot;
                if (states[slot] == 0) {
                    const target = if (tomb == cap) slot else tomb;
                    states[target] = 1;
                    keys[target] = key;
                    inserted = true;
                    break;
                }
            }
            if (!inserted and tomb != cap) {
                states[tomb] = 1;
                keys[tomb] = key;
                inserted = true;
            }
            if (inserted) successes += 1;
        } else {
            for (0..cap) |p| {
                const slot = (first + p * step) % cap;
                if (states[slot] == 0) break;
                if (states[slot] == 1 and keys[slot] == key) {
                    successes += 1;
                    if (op == 3) states[slot] = 2;
                    break;
                }
            }
        }
    }
    return successes;
}
