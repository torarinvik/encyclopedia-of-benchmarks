const MAX_ORDER: i64 = 2;
const MAX_PARSEABLE_INPUT: usize = 2;
const Frame = struct { symbol: u8, level: u8 };

fn push(stack: *[64]Frame, top: *usize, symbol: u8, level: u8) void {
    stack[top.*] = .{ .symbol = symbol, .level = level };
    top.* += 1;
}

fn emitCurve(order: u8, output: [*]u8) usize {
    var stack: [64]Frame = undefined;
    var top: usize = 0;
    var written: usize = 0;
    push(&stack,&top,5,0); push(&stack,&top,3,order);
    push(&stack,&top,7,0); push(&stack,&top,2,order);
    push(&stack,&top,9,0); push(&stack,&top,1,order);
    push(&stack,&top,11,0); push(&stack,&top,0,order);
    while (top != 0) {
        top -= 1;
        const frame = stack[top];
        if (frame.symbol >= 4) { output[written] = frame.symbol - 4; written += 1; continue; }
        if (frame.level == 0) continue;
        const child = frame.level - 1;
        switch (frame.symbol) {
            0 => {
                push(&stack,&top,0,child); push(&stack,&top,5,0); push(&stack,&top,3,child);
                push(&stack,&top,12,0); push(&stack,&top,1,child); push(&stack,&top,11,0); push(&stack,&top,0,child);
            },
            1 => {
                push(&stack,&top,1,child); push(&stack,&top,11,0); push(&stack,&top,0,child);
                push(&stack,&top,18,0); push(&stack,&top,2,child); push(&stack,&top,9,0); push(&stack,&top,1,child);
            },
            2 => {
                push(&stack,&top,2,child); push(&stack,&top,9,0); push(&stack,&top,1,child);
                push(&stack,&top,16,0); push(&stack,&top,3,child); push(&stack,&top,7,0); push(&stack,&top,2,child);
            },
            else => {
                push(&stack,&top,3,child); push(&stack,&top,7,0); push(&stack,&top,2,child);
                push(&stack,&top,14,0); push(&stack,&top,0,child); push(&stack,&top,5,0); push(&stack,&top,3,child);
            },
        }
    }
    return written;
}

pub export fn sierpinski_curve_trace(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > MAX_ORDER) return -1;
    const order: usize = @intCast(values[0]);
    var required: usize = 4;
    for (0..order) |_| required *= 4;
    if (output == null or capacity < required) return -2;
    return @intCast(emitCurve(@intCast(order), output.?));
}
