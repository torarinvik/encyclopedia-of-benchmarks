// Count sol2's bounded, source-ordered digit-factorial chains.
const std = @import("std");
const MAX_CHAIN_LENGTH: i64 = 60;
const PATH_CAPACITY: usize = 61;
const DIGIT_FACTORIALS = [_]i64{ 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 };

fn digitFactorialSum(input: i64) i64 {
    var value = input;
    var total: i64 = 0;
    while (value > 0) {
        total += DIGIT_FACTORIALS[@intCast(@mod(value, 10))];
        value = @divTrunc(value, 10);
    }
    if (input == 0) return 1;
    return total;
}

fn cacheContains(value: i64, number_limit: i64, cache: []const u32) bool {
    return value >= 1 and value < number_limit and cache[@intCast(value)] != 0;
}

fn pathContains(path: []const i64, value: i64) bool {
    for (path) |term| {
        if (term == value) return true;
    }
    return false;
}

export fn problem74_sol2(chain_length: i64, number_limit: i64) i64 {
    if (chain_length < 1 or chain_length > MAX_CHAIN_LENGTH or
        number_limit < 1 or number_limit > 1_000_000) return -1;
    if (number_limit == 1) return 0;

    const allocator = std.heap.page_allocator;
    const cache = allocator.alloc(u32, @intCast(number_limit)) catch return -1;
    defer allocator.free(cache);
    @memset(cache, 0);
    var chains_counter: i64 = 0;
    var start: i64 = 1;
    while (start < number_limit) : (start += 1) {
        var path = [_]i64{0} ** PATH_CAPACITY;
        var path_length: usize = 0;
        var chain_set_length: i64 = 0;
        var chain_element = start;
        while (!cacheContains(chain_element, number_limit, cache[0..]) and
            !pathContains(path[0..path_length], chain_element) and chain_set_length <= chain_length) {
            path[path_length] = chain_element;
            path_length += 1;
            chain_set_length += 1;
            chain_element = digitFactorialSum(chain_element);
        }
        if (cacheContains(chain_element, number_limit, cache[0..])) {
            chain_set_length += cache[@intCast(chain_element)];
        }

        cache[@intCast(start)] = @intCast(chain_set_length);
        if (chain_set_length == chain_length) chains_counter += 1;
    }
    return chains_counter;
}
