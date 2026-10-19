const buffer_size: usize = 2048;
const max_output_bytes: usize = 14;
const min_passes: i64 = 0;
const max_passes: i64 = 1000;

fn execute(sum: *u32, opcode: i32) void { sum.* +%= @intCast(opcode); }

fn eval(commands: *const [buffer_size]i32, sum: *u32) void {
    var pc: usize = 0;
    var opcode = commands[pc];
    pc += 1;
    while (opcode != 0) {
        switch (opcode) {
            1...31 => execute(sum, opcode),
            else => return,
        }
        opcode = commands[pc];
        pc += 1;
    }
}

fn formatOutput(sum_input: u32, staged: *[max_output_bytes]u8) usize {
    @memcpy(staged[0..5], "Sum: ");
    var used: usize = 5;
    var reversed: [10]u8 = undefined;
    var digits: usize = 0;
    var sum = sum_input;
    while (true) {
        reversed[digits] = @intCast(48 + sum % 10);
        digits += 1;
        sum /= 10;
        if (sum == 0) break;
    }
    while (digits > 0) {
        digits -= 1;
        staged[used] = reversed[digits];
        used += 1;
    }
    staged[used] = '\n';
    return used + 1;
}

export fn evalloop(passes: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (passes < min_passes or passes > max_passes) return -1;
    if (output_opt == null) return -2;

    var commands: [buffer_size]i32 = @splat(0);
    for (0..buffer_size - 1) |index| commands[index] = @intCast(index % 31 + 1);
    var sum: u32 = 0;
    var pass: i64 = 0;
    while (pass < passes) : (pass += 1) eval(&commands, &sum);

    var staged: [max_output_bytes]u8 = undefined;
    const used = formatOutput(sum, &staged);
    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
