// Uncompiled inverse using the transposed subgroup transform.
const std = @import("std");
const plan = @import("symmetric_group_convolution_fft_plan.zig");
const transform = @import("symmetric_group_convolution_fft_forward.zig");
const Allocator = std.mem.Allocator;

fn invariantDiagonal(alloc: Allocator, rep: plan.Representation) plan.Failure![]i64 {
    const d = rep.basis_len;
    const weights = try alloc.alloc(i64, d);
    @memset(weights, -1);
    const queue = try alloc.alloc(usize, d);
    for (0..d) |start| {
        if (weights[start] != -1) continue;
        weights[start] = 1;
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = start;
        while (head < tail) {
            const source = queue[head];
            head += 1;
            for (rep.adjacent) |generator| {
                const edge = generator[source];
                if (edge.partner) |target| {
                    if (target >= d) return error.Invariant;
                    const back = generator[target];
                    if (back.partner == null or back.partner.? != source or
                        edge.coefficient == 0 or back.coefficient == 0) return error.Invariant;
                    var candidate = @mod(weights[source]*back.coefficient, plan.modulus);
                    candidate = @mod(candidate*plan.power(edge.coefficient, plan.modulus-2), plan.modulus);
                    if (weights[target] == -1) {
                        if (tail >= d) return error.Invariant;
                        weights[target] = candidate;
                        queue[tail] = target;
                        tail += 1;
                    } else if (weights[target] != candidate) return error.Invariant;
                }
            }
        }
    }
    return weights;
}

fn transposeForward(alloc: Allocator, levels: *const plan.Plan, n: usize,
                    gradients: transform.Blocks) plan.Failure![]i64 {
    if (n < 1 or n > 9 or gradients.len != levels[n].len) return error.Invariant;
    const output = try alloc.alloc(i64, plan.factorials[n]);
    @memset(output, 0);
    if (n == 1) {
        if (gradients[0].len != 1) return error.Invariant;
        output[0] = gradients[0][0];
        return output;
    }
    const level = levels[n];
    for (0..n) |image| {
        var temporary = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer temporary.deinit();
        const scratch = temporary.allocator();
        const child = try transform.makeBlocks(scratch, levels[n-1]);
        for (level.items[0..level.len], 0..) |rep, shape| {
            var matrix_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer matrix_arena.deinit();
            const matrix_alloc = matrix_arena.allocator();
            const d = rep.basis_len;
            if (gradients[shape].len != d*d) return error.Invariant;
            var current = try matrix_alloc.dupe(i64, gradients[shape]);
            var next = try matrix_alloc.alloc(i64, d*d);
            for (image..n-1) |generator| {
                try transform.applyGenerator(rep.adjacent[generator], current, next, true);
                std.mem.swap([]i64, &current, &next);
            }
            var generator = n-2;
            while (generator > image) {
                generator -= 1;
                try transform.applyGenerator(rep.adjacent[generator], current, next, true);
                std.mem.swap([]i64, &current, &next);
            }
            for (rep.restrictions[0..rep.restriction_count]) |entry| {
                if (entry.child >= child.len or entry.offset > d or entry.width > d-entry.offset or
                    child[entry.child].len != entry.width*entry.width) return error.Invariant;
                for (0..entry.width) |row| for (0..entry.width) |col| {
                    const target = row*entry.width+col;
                    child[entry.child][target] = @mod(child[entry.child][target] +
                        current[(entry.offset+row)*d+entry.offset+col], plan.modulus);
                };
            }
        }
        const restricted = try transposeForward(scratch, levels, n-1, child);
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
            output[transform.rankPermutation(permutation[0..n])] = restricted[index];
            index += 1;
            if (!transform.nextPermutation(h[0..n-1])) break;
        }
        if (index != restricted.len) return error.Invariant;
    }
    return output;
}

pub fn inverse(alloc: Allocator, levels: *const plan.Plan, n: usize,
               blocks: transform.Blocks) plan.Failure![]i64 {
    if (n < 1 or n > 9 or blocks.len != levels[n].len) return error.Invariant;
    var temporary = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer temporary.deinit();
    const scratch = temporary.allocator();
    const weighted = try transform.makeBlocks(scratch, levels[n]);
    const inverse_order = plan.power(@intCast(plan.factorials[n]), plan.modulus-2);
    for (levels[n].items[0..levels[n].len], 0..) |rep, shape| {
        var diagonal_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer diagonal_arena.deinit();
        const diagonal_alloc = diagonal_arena.allocator();
        const d = rep.basis_len;
        if (blocks[shape].len != d*d) return error.Invariant;
        const diagonal = try invariantDiagonal(diagonal_alloc, rep);
        const inverse_diagonal = try diagonal_alloc.alloc(i64, d);
        for (diagonal, 0..) |value, i| inverse_diagonal[i] = plan.power(value, plan.modulus-2);
        for (0..d) |row| for (0..d) |col| {
            var value = @mod(blocks[shape][row*d+col]*@as(i64, @intCast(d)), plan.modulus);
            value = @mod(value*inverse_order, plan.modulus);
            value = @mod(value*diagonal[row], plan.modulus);
            weighted[shape][row*d+col] = @mod(value*inverse_diagonal[col], plan.modulus);
        };
    }
    return transposeForward(alloc, levels, n, weighted);
}
