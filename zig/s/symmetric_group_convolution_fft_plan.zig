// Uncompiled representation-planning draft. The caller owns the allocator and
// must keep its allocations alive for the lifetime of the returned levels.
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const modulus: i64 = 998244353;
pub const factorials = [_]usize{ 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 };
pub const Shape = [9]u8;
pub const Tableau = [9]u8;
pub const Column = struct { diagonal: i64, partner: ?usize, coefficient: i64 };
pub const Embedding = struct { child: usize, offset: usize, width: usize };
pub const Representation = struct {
    shape: Shape,
    basis: []Tableau,
    basis_len: usize,
    adjacent: [][]Column,
    restrictions: [9]Embedding,
    restriction_count: usize,
};
pub const Level = struct { items: []Representation, len: usize };
pub const Plan = [10]Level;
pub const Failure = error{ OutOfMemory, Invariant };

pub fn power(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var value: i64 = 1;
    while (exponent > 0) : (exponent >>= 1) {
        if ((exponent & 1) != 0) value = @mod(value * base, modulus);
        base = @mod(base * base, modulus);
    }
    return value;
}

fn shapeLess(a: Shape, b: Shape) bool {
    for (a, b) |x, y| {
        if (x != y) return x < y;
    }
    return false;
}

fn tableauLess(a: Tableau, b: Tableau, degree: usize) bool {
    var i = degree;
    while (i > 0) {
        i -= 1;
        if (a[i] != b[i]) return a[i] < b[i];
    }
    return false;
}

fn appendTableau(alloc: Allocator, rep: *Representation, tableau: Tableau) Failure!void {
    if (rep.basis_len == rep.basis.len) {
        const larger = try alloc.alloc(Tableau, @max(4, rep.basis.len * 2));
        @memcpy(larger[0..rep.basis_len], rep.basis[0..rep.basis_len]);
        rep.basis = larger;
    }
    rep.basis[rep.basis_len] = tableau;
    rep.basis_len += 1;
}

fn enumerate(alloc: Allocator, level: *Level, degree: usize, next: usize,
             shape: *Shape, tableau: *Tableau) Failure!void {
    if (next == degree) {
        var index: usize = 0;
        while (index < level.len and !std.mem.eql(u8, &level.items[index].shape, shape)) : (index += 1) {}
        if (index == level.len) {
            if (level.len == level.items.len) return error.Invariant;
            level.items[index] = .{ .shape = shape.*, .basis = &.{}, .basis_len = 0,
                .adjacent = &.{}, .restrictions = undefined, .restriction_count = 0 };
            level.len += 1;
        }
        try appendTableau(alloc, &level.items[index], tableau.*);
        return;
    }
    for (0..degree) |row| {
        if (row > 0 and shape[row] >= shape[row-1]) continue;
        const column = shape[row];
        tableau[next] = @intCast(row * 9 + column);
        shape[row] += 1;
        try enumerate(alloc, level, degree, next+1, shape, tableau);
        shape[row] -= 1;
        if (column == 0) break;
    }
}

fn prepareLevel(alloc: Allocator, degree: usize) Failure!Level {
    // There are 30 partitions of 9; 64 slots exceed that bound at each level.
    var level = Level{ .items = try alloc.alloc(Representation, 64), .len = 0 };
    var shape: Shape = @splat(0);
    var tableau: Tableau = @splat(0);
    try enumerate(alloc, &level, degree, 0, &shape, &tableau);
    for (1..level.len) |i| {
        var j = i;
        while (j > 0 and shapeLess(level.items[j].shape, level.items[j-1].shape)) : (j -= 1)
            std.mem.swap(Representation, &level.items[j], &level.items[j-1]);
    }
    for (level.items[0..level.len]) |*rep| {
        const basis = rep.basis[0..rep.basis_len];
        for (1..basis.len) |i| {
            var j = i;
            while (j > 0 and tableauLess(basis[j], basis[j-1], degree)) : (j -= 1)
                std.mem.swap(Tableau, &basis[j], &basis[j-1]);
        }
        rep.adjacent = try alloc.alloc([]Column, degree - 1);
        for (0..degree-1) |label| {
            const columns = try alloc.alloc(Column, basis.len);
            rep.adjacent[label] = columns;
            for (basis, 0..) |entry, index| {
                const first: i64 = entry[label];
                const second: i64 = entry[label+1];
                const distance = @mod(second, 9) - @divTrunc(second, 9) - @mod(first, 9) + @divTrunc(first, 9);
                if (distance == 0) return error.Invariant;
                const diagonal = power(@mod(distance, modulus), modulus-2);
                columns[index] = .{ .diagonal = diagonal, .partner = null, .coefficient = 0 };
                if (distance == 1 or distance == -1) continue;
                var exchanged = entry;
                std.mem.swap(u8, &exchanged[label], &exchanged[label+1]);
                var low: usize = 0;
                var high = basis.len;
                while (low < high) {
                    const mid = low + (high-low)/2;
                    if (tableauLess(basis[mid], exchanged, degree)) low = mid+1 else high = mid;
                }
                if (low == basis.len or tableauLess(exchanged, basis[low], degree) or
                    tableauLess(basis[low], exchanged, degree)) return error.Invariant;
                columns[index].partner = low;
                columns[index].coefficient = if (distance > 0) 1 else @mod(1-diagonal*diagonal, modulus);
            }
        }
    }
    return level;
}

pub fn makePlan(alloc: Allocator, degree: usize) Failure!Plan {
    if (degree < 1 or degree > 9) return error.Invariant;
    var plan: Plan = undefined;
    plan[0] = .{ .items = &.{}, .len = 0 };
    for (1..degree+1) |n| {
        plan[n] = try prepareLevel(alloc, n);
        if (n == 1) continue;
        const children = plan[n-1].items[0..plan[n-1].len];
        for (plan[n].items[0..plan[n].len]) |*parent| {
            var start: usize = 0;
            while (start < parent.basis_len) {
                const corner = parent.basis[start][n-1];
                var end = start+1;
                while (end < parent.basis_len and parent.basis[end][n-1] == corner) : (end += 1) {}
                var child_shape = parent.shape;
                const row = corner / 9;
                if (row >= 9 or child_shape[row] == 0) return error.Invariant;
                child_shape[row] -= 1;
                var child: usize = 0;
                while (child < children.len and !std.mem.eql(u8, &children[child].shape, &child_shape)) : (child += 1) {}
                if (child == children.len or children[child].basis_len != end-start or parent.restriction_count == 9)
                    return error.Invariant;
                for (0..end-start) |i| {
                    if (!std.mem.eql(u8, parent.basis[start+i][0..n-1], children[child].basis[i][0..n-1]))
                        return error.Invariant;
                }
                parent.restrictions[parent.restriction_count] = .{ .child = child, .offset = start, .width = end-start };
                parent.restriction_count += 1;
                start = end;
            }
        }
    }
    return plan;
}
