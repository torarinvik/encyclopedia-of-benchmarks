// Uncompiled subgroup-chain transform draft.
const std = @import("std");
const plan = @import("symmetric_group_convolution_fft_plan.zig");
const Allocator = std.mem.Allocator;
pub const Block = []i64;
pub const Blocks = []Block;

pub fn makeBlocks(alloc: Allocator, level: plan.Level) plan.Failure!Blocks {
    const blocks = try alloc.alloc(Block, level.len);
    for (level.items[0..level.len], 0..) |rep, i| {
        const d = rep.basis_len;
        if (d == 0 or d > std.math.maxInt(usize) / d / @sizeOf(i64)) return error.Invariant;
        blocks[i] = try alloc.alloc(i64, d*d);
        @memset(blocks[i], 0);
    }
    return blocks;
}

pub fn rankPermutation(permutation: []const usize) usize {
    var rank: usize = 0;
    for (permutation, 0..) |value, i| {
        var smaller: usize = 0;
        for (permutation[i+1..]) |other| {
            if (other < value) smaller += 1;
        }
        rank += smaller*plan.factorials[permutation.len-1-i];
    }
    return rank;
}

pub fn nextPermutation(values: []usize) bool {
    if (values.len < 2) return false;
    var pivot = values.len-1;
    while (pivot > 0 and values[pivot-1] >= values[pivot]) : (pivot -= 1) {}
    if (pivot == 0) return false;
    var successor = values.len-1;
    while (values[successor] <= values[pivot-1]) : (successor -= 1) {}
    std.mem.swap(usize, &values[pivot-1], &values[successor]);
    std.mem.reverse(usize, values[pivot..]);
    return true;
}

pub fn applyGenerator(generator: []const plan.Column, input: []const i64,
                      output: []i64, transpose: bool) plan.Failure!void {
    const d = generator.len;
    if (input.len != d*d or output.len != d*d) return error.Invariant;
    @memset(output, 0);
    for (generator, 0..) |column, row| {
        if (column.partner) |partner| {
            if (partner >= d) return error.Invariant;
        }
        for (0..d) |col| {
            if (transpose) {
                var value = @mod(column.diagonal*input[row*d+col], plan.modulus);
                if (column.partner) |partner|
                    value = @mod(value+column.coefficient*input[partner*d+col], plan.modulus);
                output[row*d+col] = value;
            } else {
                const value = input[row*d+col];
                const diagonal = row*d+col;
                output[diagonal] = @mod(output[diagonal]+column.diagonal*value, plan.modulus);
                if (column.partner) |partner| {
                    const target = partner*d+col;
                    output[target] = @mod(output[target]+column.coefficient*value, plan.modulus);
                }
            }
        }
    }
}

// Output belongs to alloc. A temporary arena per coset keeps recursive
// intermediates separate from the caller-owned output, and a second arena
// bounds generator scratch to one representation at a time.
pub fn forward(alloc: Allocator, levels: *const plan.Plan, n: usize,
               input: []const i64) plan.Failure!Blocks {
    if (n < 1 or n > 9 or input.len != plan.factorials[n]) return error.Invariant;
    const level = levels[n];
    const output = try makeBlocks(alloc, level);
    if (n == 1) { output[0][0] = input[0]; return output; }
    for (0..n) |image| {
        var temporary = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer temporary.deinit();
        const scratch = temporary.allocator();
        const restricted = try scratch.alloc(i64, plan.factorials[n-1]);
        var h: [9]usize = @splat(0);
        for (0..n-1) |i| h[i] = i;
        var index: usize = 0;
        while (true) {
            var permutation = h;
            permutation[n-1] = n-1;
            for (permutation[0..n]) |*value| {
                if (value.* == image) value.* = n-1 else if (value.* == n-1) value.* = image;
            }
            if (index >= restricted.len) return error.Invariant;
            restricted[index] = input[rankPermutation(permutation[0..n])];
            index += 1;
            if (!nextPermutation(h[0..n-1])) break;
        }
        if (index != restricted.len) return error.Invariant;
        const child = try forward(scratch, levels, n-1, restricted);
        for (level.items[0..level.len], 0..) |rep, shape| {
            var matrix_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer matrix_arena.deinit();
            const matrix_alloc = matrix_arena.allocator();
            const d = rep.basis_len;
            var current = try matrix_alloc.alloc(i64, d*d);
            var next = try matrix_alloc.alloc(i64, d*d);
            @memset(current, 0);
            for (rep.restrictions[0..rep.restriction_count]) |entry| {
                if (entry.child >= child.len or entry.offset > d or entry.width > d-entry.offset or
                    child[entry.child].len != entry.width*entry.width) return error.Invariant;
                for (0..entry.width) |row| for (0..entry.width) |col| {
                    current[(entry.offset+row)*d+entry.offset+col] = child[entry.child][row*entry.width+col];
                };
            }
            for (image..n-1) |generator| {
                try applyGenerator(rep.adjacent[generator], current, next, false);
                std.mem.swap([]i64, &current, &next);
            }
            var generator = n-2;
            while (generator > image) {
                generator -= 1;
                try applyGenerator(rep.adjacent[generator], current, next, false);
                std.mem.swap([]i64, &current, &next);
            }
            for (current, 0..) |value, i| output[shape][i] = @mod(output[shape][i]+value, plan.modulus);
        }
    }
    return output;
}
