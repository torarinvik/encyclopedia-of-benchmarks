/// Arbitrary-order line envelope with integer intersection breakpoints.
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;
const BREAKPOINT_INFINITY: i64 = 1_000_000_000_000_000;
const CHECKSUM_OFFSET: i64 = 2_000_001;

#[derive(Clone, Copy)]
struct Line { slope: i64, intercept: i64, breakpoint: i64 }

fn intersection(left: Line, right: Line) -> i64 {
    let numerator = left.intercept - right.intercept;
    let denominator = right.slope - left.slope;
    let mut quotient = numerator / denominator;
    if numerator % denominator != 0 && numerator < 0 { quotient -= 1; }
    quotient
}

fn erase_line(lines: &mut [Line; MAX_OPERATIONS], count: &mut usize, position: usize) {
    for i in position..(*count - 1) { lines[i] = lines[i + 1]; }
    *count -= 1;
}

fn insert_line(lines: &mut [Line; MAX_OPERATIONS], count: &mut usize,
               slope: i64, intercept: i64) {
    let mut position = 0usize;
    while position < *count && lines[position].slope < slope { position += 1; }
    if position < *count && lines[position].slope == slope {
        if lines[position].intercept >= intercept { return; }
        erase_line(lines, count, position);
    }
    for i in (position..*count).rev() { lines[i + 1] = lines[i]; }
    lines[position] = Line { slope, intercept, breakpoint: BREAKPOINT_INFINITY };
    *count += 1;
    let mut active = position;
    while active + 1 < *count {
        let breakpoint = intersection(lines[active], lines[active + 1]);
        lines[active].breakpoint = breakpoint;
        if breakpoint >= lines[active + 1].breakpoint { erase_line(lines, count, active + 1); }
        else { break; }
    }
    if active + 1 == *count { lines[active].breakpoint = BREAKPOINT_INFINITY; }
    if active > 0 {
        let breakpoint = intersection(lines[active - 1], lines[active]);
        lines[active - 1].breakpoint = breakpoint;
        let mut cursor;
        if breakpoint >= lines[active].breakpoint {
            erase_line(lines, count, active);
            active -= 1;
            lines[active].breakpoint = if active + 1 < *count {
                intersection(lines[active], lines[active + 1])
            } else { BREAKPOINT_INFINITY };
            cursor = active;
        } else { cursor = active - 1; }
        while cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint {
            erase_line(lines, count, cursor);
            cursor -= 1;
            active -= 1;
            lines[cursor].breakpoint = if cursor + 1 < *count {
                intersection(lines[cursor], lines[cursor + 1])
            } else { BREAKPOINT_INFINITY };
        }
    }
}

fn query(lines: &[Line; MAX_OPERATIONS], count: usize, x: i64, objective: i64) -> i64 {
    let mut low = 0usize;
    let mut high = count;
    while low < high {
        let middle = low + (high - low) / 2;
        if lines[middle].breakpoint < x { low = middle + 1; } else { high = middle; }
    }
    (lines[low].slope * x + lines[low].intercept) * objective
}

#[no_mangle]
pub extern "C" fn arbitrary_order_line_container(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let mode = input[0];
    let operation_value = input[1];
    if !(0..=1).contains(&mode) || !(0..=MAX_OPERATIONS as i64).contains(&operation_value) { return -1; }
    let operations = operation_value as usize;
    if length != 2 + 3 * operations { return -1; }
    let mut seen_line = false;
    for operation in 0..operations {
        let p = 2 + 3 * operation;
        let (opcode, first, second) = (input[p], input[p + 1], input[p + 2]);
        if opcode == 0 {
            if !(-1000..=1000).contains(&first) || !(-1000..=1000).contains(&second) { return -1; }
            seen_line = true;
        } else if opcode == 1 {
            if !seen_line || !(-1000..=1000).contains(&first) || second != 0 { return -1; }
        } else { return -1; }
    }
    let objective = if mode == 1 { 1 } else { -1 };
    let mut lines = [Line { slope: 0, intercept: 0, breakpoint: 0 }; MAX_OPERATIONS];
    let mut line_count = 0usize;
    let mut query_index = 0usize;
    let mut checksum = 0i64;
    for operation in 0..operations {
        let p = 2 + 3 * operation;
        if input[p] == 0 {
            insert_line(&mut lines, &mut line_count, input[p + 1] * objective, input[p + 2] * objective);
        } else {
            let optimum = query(&lines, line_count, input[p + 1], objective);
            checksum += (query_index as i64 + 1) * (optimum + CHECKSUM_OFFSET);
            query_index += 1;
        }
    }
    checksum
}
