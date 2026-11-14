// Uncompiled symmetric-group convolution ABI draft.
const std = @import("std");
const plan = @import("symmetric_group_convolution_fft_plan.zig");
const transform = @import("symmetric_group_convolution_fft_forward.zig");
const inversion = @import("symmetric_group_convolution_fft_inverse.zig");

fn calculate(alloc: std.mem.Allocator, n: usize, left_input: []const i64,
             right_input: []const i64) plan.Failure![]i64 {
    const levels = try plan.makePlan(alloc, n);
    const left = try transform.forward(alloc, &levels, n, left_input);
    const right = try transform.forward(alloc, &levels, n, right_input);
    const product = try transform.makeBlocks(alloc, levels[n]);
    for (levels[n].items[0..levels[n].len], 0..) |rep, shape| {
        const d = rep.basis_len;
        for (0..d) |row| for (0..d) |inner| for (0..d) |col| {
            const index = row*d+col;
            product[shape][index] = @mod(product[shape][index] +
                left[shape][row*d+inner]*right[shape][inner*d+col], plan.modulus);
        };
    }
    return inversion.inverse(alloc, &levels, n, product);
}

pub export fn symmetric_group_convolution_fft(input_opt: ?[*]const i64, length: usize,
                                               output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 725762) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 9) return -1;
    const n: usize = @intCast(input[0]);
    const count = plan.factorials[n];
    if (length != 1+2*count) return -1;
    for (1..length) |i| if (input[i] < 0 or input[i] >= plan.modulus) { return -1; };
    if (output_opt == null or capacity < 4*count) return -2;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const result = calculate(arena.allocator(), n, input[1..1+count], input[1+count..length]) catch |err| switch (err) {
        error.OutOfMemory => return -3,
        error.Invariant => return -4,
    };
    if (result.len != count) return -4;
    const output = output_opt.?;
    for (result, 0..) |value, i| {
        const bits: u32 = @intCast(value);
        for (0..4) |byte| output[4*i+byte] = @truncate(bits >> @as(u5, @intCast(8*byte)));
    }
    return @intCast(4*count);
}
