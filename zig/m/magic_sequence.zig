const MAX_N: usize = 11;
const FNV_OFFSET_BASIS: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;
const I64_RESULT_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn fnvByte(hash: *u64, value: u8) void {
    hash.* = (hash.* ^ @as(u64, value)) *% FNV_PRIME;
}

fn enumerate(n: usize, hash: *u64, hash_rows: bool) u32 {
    if (n == 0) return 1;

    var vector: [MAX_N]u8 = @splat(0);
    var frequencies: [MAX_N]u8 = @splat(0);
    var next_candidate: [MAX_N]u8 = @splat(0);
    var prefix_sum: [MAX_N + 1]u8 = @splat(0);
    var depth: usize = 0;
    var solution_count: u32 = 0;

    while (true) {
        if (depth == n) {
            var is_magic = true;
            for (0..n) |symbol| {
                if (frequencies[symbol] != vector[symbol]) {
                    is_magic = false;
                    break;
                }
            }
            if (is_magic) {
                solution_count += 1;
                if (hash_rows) {
                    for (0..n) |index| fnvByte(hash, vector[index]);
                }
            }
            depth -= 1;
            frequencies[@as(usize, vector[depth])] -= 1;
            continue;
        }

        const candidate = next_candidate[depth];
        if (@as(usize, candidate) >= n) {
            next_candidate[depth] = 0;
            if (depth == 0) break;
            depth -= 1;
            frequencies[@as(usize, vector[depth])] -= 1;
            continue;
        }
        next_candidate[depth] = candidate + 1;
        const sum: usize = @as(usize, prefix_sum[depth]) + @as(usize, candidate);
        if (sum > n) continue;

        vector[depth] = candidate;
        frequencies[@as(usize, candidate)] += 1;
        prefix_sum[depth + 1] = @intCast(sum);
        depth += 1;
        next_candidate[depth] = 0;
    }
    return solution_count;
}

export fn magic_sequence(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const n_value = input.?[0];
    if (n_value < 0 or n_value > 11) return -1;
    const n: usize = @intCast(n_value);

    var hash = FNV_OFFSET_BASIS;
    fnvByte(&hash, @intCast(n));
    const solution_count = enumerate(n, &hash, false);
    for (0..4) |byte| {
        fnvByte(&hash, @truncate(solution_count >> @as(u5, @intCast(byte * 8))));
    }
    _ = enumerate(n, &hash, true);
    return @intCast(hash & I64_RESULT_MASK);
}
