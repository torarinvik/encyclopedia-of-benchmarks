const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const ELEMENT_COUNT: usize = 500;
const MAX_OUTPUT_BYTES: usize = 700;
const PassResult = struct { value: i32, endpoint_error: bool };

fn buildAndSortPass(run: usize) PassResult {
    var sortlist: [ELEMENT_COUNT + 1]i32 = undefined;
    var biggest: i32 = 0;
    var littlest: i32 = 0;
    var seed: i64 = 74755;
    for (1..ELEMENT_COUNT + 1) |index| {
        seed = (seed * 1309 + 13849) & 65535;
        const temp = seed;
        sortlist[index] = @intCast(temp - @divTrunc(temp, 100000) * 100000 - 50000);
        if (sortlist[index] > biggest) {
            biggest = sortlist[index];
        } else if (sortlist[index] < littlest) {
            littlest = sortlist[index];
        }
    }
    var top: usize = ELEMENT_COUNT;
    while (top > 1) {
        var index: usize = 1;
        while (index < top) : (index += 1) {
            if (sortlist[index] > sortlist[index + 1]) {
                const temp = sortlist[index];
                sortlist[index] = sortlist[index + 1];
                sortlist[index + 1] = temp;
            }
        }
        top -= 1;
    }
    return .{
        .value = sortlist[run + 1],
        .endpoint_error = sortlist[1] != littlest or sortlist[ELEMENT_COUNT] != biggest,
    };
}

fn appendText(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, text: []const u8) void {
    for (text) |byte| { buffer[used.*] = byte; used.* += 1; }
}

fn appendInteger(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value: i32) void {
    var remaining = value;
    if (remaining < 0) { buffer[used.*] = '-'; used.* += 1; remaining = -remaining; }
    var reverse: [12]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reverse[count] = @intCast(48 + @mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    while (count > 0) { count -= 1; buffer[used.*] = reverse[count]; used.* += 1; }
}

export fn stanford_bubblesort(runs: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (runs < MIN_RUNS or runs > MAX_RUNS) return -1;
    if (output_opt == null) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    for (0..@intCast(runs)) |run| {
        const item = buildAndSortPass(run);
        if (item.endpoint_error) appendText(&staged, &used, "Error3 in Bubble.\n");
        appendInteger(&staged, &used, item.value);
        appendText(&staged, &used, "\n");
    }
    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
