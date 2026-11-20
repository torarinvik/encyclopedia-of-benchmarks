const std = @import("std");

const MAX_VERTICES: usize = 7;
const MAX_SHAPES: usize = 48;
const MAX_WIDTH: usize = 15;
const MAX_CANDIDATES: usize = 37;
const MAX_OUTPUT: usize = 674;

const Candidate = struct {
    size: usize,
    text: [MAX_WIDTH]u8,
};

const Generator = struct {
    shapes: [MAX_VERTICES + 1][MAX_SHAPES][MAX_WIDTH]u8,
    counts: [MAX_VERTICES + 1]usize,
    candidates: [MAX_CANDIDATES]Candidate,
    candidate_count: usize,
    target: usize,
};

fn textLess(left: *const [MAX_WIDTH]u8, right: *const [MAX_WIDTH]u8) bool {
    for (0..MAX_WIDTH) |index| {
        if (left[index] != right[index]) return left[index] < right[index];
        if (left[index] == 0) return false;
    }
    return false;
}

fn shapeLess(left: *const [MAX_WIDTH]u8, right: *const [MAX_WIDTH]u8, width: usize) bool {
    for (0..width) |index| {
        if (left[index] != right[index]) return left[index] < right[index];
    }
    return false;
}

fn enumerateMultisets(g: *Generator, start: usize, remaining: usize,
    children: *[MAX_WIDTH]u8, child_length: usize) void {
    if (remaining == 0) {
        const index = g.counts[g.target];
        if (index >= MAX_SHAPES) return;
        const shape = &g.shapes[g.target][index];
        shape[0] = '(';
        @memcpy(shape[1 .. child_length + 1], children.*[0..child_length]);
        shape[child_length + 1] = ')';
        shape[child_length + 2] = 0;
        g.counts[g.target] = index + 1;
        return;
    }

    for (start..g.candidate_count) |index| {
        const candidate = g.candidates[index];
        if (candidate.size > remaining) continue;
        const encoded_length = 2 * candidate.size;
        @memcpy(children.*[child_length .. child_length + encoded_length],
            candidate.text[0..encoded_length]);
        enumerateMultisets(g, index, remaining - candidate.size, children,
            child_length + encoded_length);
    }
}

fn sortShapes(g: *Generator, size: usize) void {
    for (1..g.counts[size]) |index| {
        const value = g.shapes[size][index];
        var position = index;
        while (position > 0 and shapeLess(&value, &g.shapes[size][position - 1], 2 * size)) {
            g.shapes[size][position] = g.shapes[size][position - 1];
            position -= 1;
        }
        g.shapes[size][position] = value;
    }
}

fn buildShapes(g: *Generator, maximum: usize) void {
    g.counts[1] = 1;
    g.shapes[1][0][0] = '(';
    g.shapes[1][0][1] = ')';
    g.shapes[1][0][2] = 0;

    for (2..maximum + 1) |target| {
        g.target = target;
        g.candidate_count = 0;
        for (1..target) |size| {
            for (0..g.counts[size]) |index| {
                const candidate = Candidate{ .size = size, .text = g.shapes[size][index] };
                var position = g.candidate_count;
                while (position > 0 and textLess(&candidate.text,
                    &g.candidates[position - 1].text)) {
                    g.candidates[position] = g.candidates[position - 1];
                    position -= 1;
                }
                g.candidates[position] = candidate;
                g.candidate_count += 1;
            }
        }

        var children = [_]u8{0} ** MAX_WIDTH;
        enumerateMultisets(g, 0, target - 1, &children, 0);
        sortShapes(g, target);
    }
}

export fn list_rooted_trees(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length != 1 or input[0] < 1 or input[0] > @as(i64, @intCast(MAX_VERTICES))) return -1;
    const vertices: usize = @intCast(input[0]);

    var generator = std.mem.zeroes(Generator);
    buildShapes(&generator, vertices);
    const count = generator.counts[vertices];
    const width = 2 * vertices;
    const needed = 2 + count * width;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    staged[0] = @intCast(count & 0xff);
    staged[1] = @intCast((count >> 8) & 0xff);
    var position: usize = 2;
    for (0..count) |index| {
        @memcpy(staged[position .. position + width],
            generator.shapes[vertices][index][0..width]);
        position += width;
    }

    const output = output_opt orelse return -2;
    if (capacity < needed) return -2;
    @memcpy(output[0..needed], staged[0..needed]);
    return @intCast(needed);
}
