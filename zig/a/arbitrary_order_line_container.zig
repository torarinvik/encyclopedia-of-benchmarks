const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;
const BREAKPOINT_INFINITY: i64 = 1_000_000_000_000_000;
const CHECKSUM_OFFSET: i64 = 2_000_001;

const Line = struct { slope: i64, intercept: i64, breakpoint: i64 };

fn floorDiv(numerator: i64, denominator: i64) i64 {
    var quotient = @divTrunc(numerator, denominator);
    if (@rem(numerator, denominator) != 0 and numerator < 0) quotient -= 1;
    return quotient;
}

fn intersection(left: Line, right: Line) i64 {
    return floorDiv(left.intercept - right.intercept, right.slope - left.slope);
}

fn eraseLine(lines: *[MAX_OPERATIONS]Line, count: *usize, position: usize) void {
    var i = position;
    while (i + 1 < count.*) : (i += 1) lines[i] = lines[i + 1];
    count.* -= 1;
}

fn insertLine(lines: *[MAX_OPERATIONS]Line, count: *usize, slope: i64, intercept: i64) void {
    var position: usize = 0;
    while (position < count.* and lines[position].slope < slope) : (position += 1) {}
    if (position < count.* and lines[position].slope == slope) {
        if (lines[position].intercept >= intercept) return;
        eraseLine(lines, count, position);
    }
    var shift = count.*;
    while (shift > position) : (shift -= 1) lines[shift] = lines[shift - 1];
    lines[position] = .{ .slope = slope, .intercept = intercept, .breakpoint = BREAKPOINT_INFINITY };
    count.* += 1;
    var active = position;
    while (active + 1 < count.*) {
        const breakpoint = intersection(lines[active], lines[active + 1]);
        lines[active].breakpoint = breakpoint;
        if (breakpoint >= lines[active + 1].breakpoint) eraseLine(lines, count, active + 1) else break;
    }
    if (active + 1 == count.*) lines[active].breakpoint = BREAKPOINT_INFINITY;
    if (active > 0) {
        const breakpoint = intersection(lines[active - 1], lines[active]);
        lines[active - 1].breakpoint = breakpoint;
        var cursor: usize = 0;
        if (breakpoint >= lines[active].breakpoint) {
            eraseLine(lines, count, active);
            active -= 1;
            lines[active].breakpoint = if (active + 1 < count.*)
                intersection(lines[active], lines[active + 1]) else BREAKPOINT_INFINITY;
            cursor = active;
        } else cursor = active - 1;
        while (cursor > 0 and lines[cursor - 1].breakpoint >= lines[cursor].breakpoint) {
            eraseLine(lines, count, cursor);
            cursor -= 1;
            active -= 1;
            lines[cursor].breakpoint = if (cursor + 1 < count.*)
                intersection(lines[cursor], lines[cursor + 1]) else BREAKPOINT_INFINITY;
        }
    }
}

fn lineQuery(lines: *const [MAX_OPERATIONS]Line, count: usize, x: i64, objective: i64) i64 {
    var low: usize = 0;
    var high = count;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (lines[middle].breakpoint < x) low = middle + 1 else high = middle;
    }
    return (lines[low].slope * x + lines[low].intercept) * objective;
}

export fn arbitrary_order_line_container(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const mode = input[0];
    const operation_value = input[1];
    if ((mode != 0 and mode != 1) or operation_value < 0 or operation_value > MAX_OPERATIONS) return -1;
    const operations: usize = @intCast(operation_value);
    if (length != 2 + 3 * operations) return -1;
    var seen_line = false;
    for (0..operations) |operation| {
        const p = 2 + 3 * operation;
        const opcode = input[p];
        const first = input[p + 1];
        const second = input[p + 2];
        if (opcode == 0) {
            if (first < -1000 or first > 1000 or second < -1000 or second > 1000) return -1;
            seen_line = true;
        } else if (opcode == 1) {
            if (!seen_line or first < -1000 or first > 1000 or second != 0) return -1;
        } else return -1;
    }
    const objective: i64 = if (mode == 1) 1 else -1;
    var lines: [MAX_OPERATIONS]Line = @splat(.{ .slope = 0, .intercept = 0, .breakpoint = 0 });
    var line_count: usize = 0;
    var query_index: usize = 0;
    var checksum: i64 = 0;
    for (0..operations) |operation| {
        const p = 2 + 3 * operation;
        if (input[p] == 0) {
            insertLine(&lines, &line_count, input[p + 1] * objective, input[p + 2] * objective);
        } else {
            const optimum = lineQuery(&lines, line_count, input[p + 1], objective);
            checksum += @as(i64, @intCast(query_index + 1)) * (optimum + CHECKSUM_OFFSET);
            query_index += 1;
        }
    }
    return checksum;
}
