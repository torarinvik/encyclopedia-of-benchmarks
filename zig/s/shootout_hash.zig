const std = @import("std");

const max_n: i64 = 3_500_000;
const bucket_primes = [_]u32{
    53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
    49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
    6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
    402653189, 805306457, 1610612741, 3221225473, 4294967291,
};

fn bucketCountFor(n: u32) usize {
    for (bucket_primes) |prime| {
        if (prime >= n) return @intCast(prime);
    }
    return @intCast(bucket_primes[bucket_primes.len - 1]);
}

fn hashKey(value_input: u32, base: u32, bucket_count: usize) usize {
    var value = value_input;
    var reverse: [16]u8 = @splat(0);
    var length: usize = 0;
    while (true) {
        const digit = value % base;
        reverse[length] = if (digit < 10) @intCast(48 + digit) else @intCast(87 + digit);
        length += 1;
        value /= base;
        if (value == 0) break;
    }
    var hash: u64 = 0;
    while (length > 0) {
        length -= 1;
        hash = 5 * hash + reverse[length];
    }
    return @intCast(hash % @as(u64, @intCast(bucket_count)));
}

fn hexKeyMatchesDecimal(hex_value_input: u32, decimal_value_input: u32) bool {
    var hex_value = hex_value_input;
    var decimal_value = decimal_value_input;
    while (hex_value != 0 and decimal_value != 0) {
        const digit = hex_value & 15;
        if (digit >= 10 or digit != decimal_value % 10) return false;
        hex_value >>= 4;
        decimal_value /= 10;
    }
    return hex_value == 0 and decimal_value == 0;
}

export fn shootout_hash(n: i64) i64 {
    if (n < 0 or n > max_n) return -1;
    const bound: u32 = @intCast(n);
    const bucket_count = bucketCountFor(bound);
    const allocator = std.heap.page_allocator;
    const heads = allocator.alloc(u32, bucket_count) catch return -1;
    defer allocator.free(heads);
    const next = allocator.alloc(u32, @as(usize, @intCast(bound)) + 1) catch return -1;
    defer allocator.free(next);
    @memset(heads, 0);
    @memset(next, 0);

    var value: u32 = 1;
    while (value <= bound) : (value += 1) {
        const bucket = hashKey(value, 16, bucket_count);
        var node = heads[bucket];
        var previous: u32 = 0;
        while (node != 0) {
            if (node == value) break;
            previous = node;
            node = next[@intCast(node)];
        }
        if (node == 0) {
            if (previous == 0) heads[bucket] = value else next[@intCast(previous)] = value;
        }
    }

    var found: i64 = 0;
    value = bound;
    while (value > 0) : (value -= 1) {
        const bucket = hashKey(value, 10, bucket_count);
        var node = heads[bucket];
        while (node != 0) {
            if (hexKeyMatchesDecimal(node, value)) {
                found += 1;
                break;
            }
            node = next[@intCast(node)];
        }
    }
    return found;
}
