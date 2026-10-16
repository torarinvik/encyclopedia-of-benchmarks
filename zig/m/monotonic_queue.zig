const MAX_N: usize = 4096;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashI32(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte_index| {
        result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    }
    return result;
}

export fn monotonic_queue(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_N + 2) return -1;
    const n64 = input[0]; const window64 = input[1];
    if (n64 < 1 or n64 > MAX_N or window64 < 1 or window64 > n64 or length != @as(usize, @intCast(n64)) + 2) return -1;
    const n: usize = @intCast(n64); const window: usize = @intCast(window64);
    for (0..n) |i| if (input[2 + i] < -2147483648 or input[2 + i] > 2147483647) return -1;
    var deque: [MAX_N]usize = undefined; var head: usize = 0; var tail: usize = 0;
    var hash: u64 = FNV_OFFSET;
    for (0..n) |i| {
        while (head < tail and deque[head] + window <= i) : (head += 1) {}
        while (head < tail and input[2 + deque[tail - 1]] <= input[2 + i]) : (tail -= 1) {}
        deque[tail] = i; tail += 1;
        if (i + 1 >= window) hash = hashI32(hash, input[2 + deque[head]]);
    }
    return @intCast(hash & 0x7fffffffffffffff);
}
