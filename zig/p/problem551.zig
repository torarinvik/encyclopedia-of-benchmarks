const std = @import("std");

const max_n: i64 = 1_000_000_000_000_000;
const state_capacity: usize = 32_768;
const state_capacity_i64: i64 = 32_768;
const jump_capacity: usize = 131_072;
const table_mask: usize = state_capacity - 1;

const State = struct { prefix_sum: i32, suffix: i64, head: i32 };
const Jump = struct { difference: i64, terms: i64, k: i32, next: i32 };
const Step = struct { difference: i64, terms: i64 };
const Memo = struct {
    states: []State,
    jumps: []Jump,
    jump_count: usize = 0,
    failed: bool = false,
};

fn power10(exponent: i64) i64 {
    var value: i64 = 1;
    var index: i64 = 0;
    while (index < exponent) : (index += 1) value *= 10;
    return value;
}

fn digitSum(input: i64) i64 {
    var value = input;
    var total: i64 = 0;
    while (value > 0) {
        total += @mod(value, 10);
        value = @divTrunc(value, 10);
    }
    return total;
}

fn findState(memo: *Memo, prefix_sum: i64, suffix: i64) ?usize {
    const slot: usize = @intCast(@mod(@mod(suffix, state_capacity_i64) + prefix_sum * 1009, state_capacity_i64));
    var probe: usize = 0;
    while (probe < state_capacity) : (probe += 1) {
        const index = (slot + probe) & table_mask;
        if (memo.states[index].head == -2) {
            memo.states[index] = .{ .prefix_sum = @intCast(prefix_sum), .suffix = suffix, .head = -1 };
            return index;
        }
        if (@as(i64, memo.states[index].prefix_sum) == prefix_sum and memo.states[index].suffix == suffix) return index;
    }
    memo.failed = true;
    return null;
}

fn addJump(memo: *Memo, state_index: usize, difference: i64, terms: i64, k: i64) void {
    if (memo.jump_count >= jump_capacity) {
        memo.failed = true;
        return;
    }
    const index = memo.jump_count;
    memo.jump_count += 1;
    memo.jumps[index] = .{
        .difference = difference,
        .terms = terms,
        .k = @intCast(k),
        .next = memo.states[state_index].head,
    };
    memo.states[state_index].head = @intCast(index);
}

fn compute(value: *i64, k: i64, index_input: i64, target: i64) Step {
    var index = index_input;
    const start = index;
    const base = power10(k);
    const prefix_sum = digitSum(@divTrunc(value.*, base));
    var suffix = @mod(value.*, base);
    var difference: i64 = 0;
    while (index < target) {
        index += 1;
        const addend = prefix_sum + digitSum(suffix);
        difference += addend;
        suffix += addend;
        if (suffix >= base) break;
    }
    value.* += difference;
    return .{ .difference = difference, .terms = index - start };
}

fn nextTerm(value: *i64, k: i64, index: i64, target: i64, memo: *Memo) Step {
    const base = power10(k);
    const prefix_sum = digitSum(@divTrunc(value.*, base));
    const suffix = @mod(value.*, base);
    const max_terms = target - index;
    const state_index = findState(memo, prefix_sum, suffix) orelse return .{ .difference = 0, .terms = 0 };
    var difference: i64 = 0;
    var terms: i64 = 0;
    var best: i32 = -1;
    var jump = memo.states[state_index].head;
    while (jump >= 0) {
        const entry = memo.jumps[@intCast(jump)];
        if (@as(i64, entry.k) <= k and entry.terms <= max_terms and
            (best < 0 or entry.terms > memo.jumps[@intCast(best)].terms)) best = jump;
        jump = entry.next;
    }
    if (best >= 0) {
        const entry = memo.jumps[@intCast(best)];
        difference = entry.difference;
        terms = entry.terms;
        value.* += difference;
    }
    if (terms >= max_terms or suffix + difference >= base) return .{ .difference = difference, .terms = terms };
    if (k > 2) {
        while (!memo.failed) {
            const extra = nextTerm(value, k - 1, index + terms, target, memo);
            difference += extra.difference;
            terms += extra.terms;
            if (terms >= max_terms or suffix + difference >= base) break;
        }
    } else {
        const extra = compute(value, k, index + terms, target);
        difference += extra.difference;
        terms += extra.terms;
    }
    if (!memo.failed and terms < max_terms) addJump(memo, state_index, difference, terms, k);
    return .{ .difference = difference, .terms = terms };
}

export fn problem551(n: i64) i64 {
    if (n < 1 or n > max_n) return -1;
    const allocator = std.heap.page_allocator;
    const states = allocator.alloc(State, state_capacity) catch return -1;
    defer allocator.free(states);
    const jumps = allocator.alloc(Jump, jump_capacity) catch return -1;
    defer allocator.free(jumps);
    @memset(states, .{ .prefix_sum = 0, .suffix = 0, .head = -2 });
    @memset(jumps, .{ .difference = 0, .terms = 0, .k = 0, .next = -1 });
    var memo = Memo{ .states = states, .jumps = jumps };
    var value: i64 = 1;
    var jumped: i64 = 0;
    while (jumped != n - 1 and !memo.failed) {
        const step = nextTerm(&value, 18, 1 + jumped, n, &memo);
        jumped += step.terms;
    }
    return if (memo.failed) -1 else value;
}
