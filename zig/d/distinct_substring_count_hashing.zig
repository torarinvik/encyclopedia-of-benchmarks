const MAX_TEXT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MODULUS: i64 = 1_000_000_007;

export fn distinct_substring_count_hashing(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length == 0 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_TEXT or length != @as(usize, @intCast(n_value + 1))) return -1;
    const n: usize = @intCast(n_value);
    var prefix: [65]i64 = [_]i64{0} ** 65;
    var powers: [65]i64 = [_]i64{0} ** 65;
    powers[0] = 1;
    for (0..n) |i| {
        const symbol = input[i + 1];
        if (symbol < 0 or symbol > 255) return -1;
        prefix[i + 1] = @mod(prefix[i] * 257 + symbol + 1, MODULUS);
        powers[i + 1] = @mod(powers[i] * 257, MODULUS);
    }

    var group_hash: [64]i64 = undefined;
    var group_head: [64]i64 = undefined;
    var representative_start: [64]i64 = undefined;
    var representative_next: [64]i64 = undefined;
    var distinct: i64 = 0;
    for (1..n + 1) |width| {
        for (0..64) |slot| {
            group_hash[slot] = -1;
            group_head[slot] = -1;
        }
        var representative_count: usize = 0;
        for (0..n - width + 1) |start| {
            const end = start + width;
            var fingerprint = @mod(prefix[end] - @mod(prefix[start] * powers[width], MODULUS), MODULUS);
            if (fingerprint < 0) fingerprint += MODULUS;
            var slot: usize = @intCast(@mod(fingerprint, 64));
            while (group_hash[slot] != -1 and group_hash[slot] != fingerprint) slot = (slot + 1) % 64;
            if (group_hash[slot] == -1) group_hash[slot] = fingerprint;

            var duplicate = false;
            var prior = group_head[slot];
            while (prior >= 0) {
                const old_start: usize = @intCast(representative_start[@intCast(prior)]);
                var offset: usize = 0;
                while (offset < width and input[start + offset + 1] == input[old_start + offset + 1]) : (offset += 1) {}
                if (offset == width) {
                    duplicate = true;
                    break;
                }
                prior = representative_next[@intCast(prior)];
            }
            if (!duplicate) {
                representative_start[representative_count] = @intCast(start);
                representative_next[representative_count] = group_head[slot];
                group_head[slot] = @intCast(representative_count);
                representative_count += 1;
                distinct += 1;
            }
        }
    }
    return distinct;
}
