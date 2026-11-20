module arbitrary_order_line_container;

const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 99;
const long BREAKPOINT_INFINITY = 1000000000000000L;
const long CHECKSUM_OFFSET = 2000001L;

struct AolcLine { long slope; long intercept; long breakpoint; }

fn long floor_div(long numerator, long denominator) {
    long quotient = numerator / denominator;
    if (numerator % denominator != 0 && numerator < 0) quotient--;
    return quotient;
}

fn long intersection(AolcLine left, AolcLine right) {
    return floor_div(left.intercept - right.intercept, right.slope - left.slope);
}

fn usz erase_line(AolcLine* lines, usz count, usz position) {
    for (usz i = position; i + 1 < count; i++) lines[i] = lines[i + 1];
    return count - 1;
}

fn usz insert_line(AolcLine* lines, usz count, long slope, long intercept) {
    usz position = 0;
    while (position < count && lines[position].slope < slope) position++;
    if (position < count && lines[position].slope == slope) {
        if (lines[position].intercept >= intercept) return count;
        count = erase_line(lines, count, position);
    }
    for (usz i = count; i > position; i--) lines[i] = lines[i - 1];
    lines[position] = AolcLine{slope, intercept, BREAKPOINT_INFINITY};
    count++;
    usz active = position;
    while (active + 1 < count) {
        long breakpoint = intersection(lines[active], lines[active + 1]);
        lines[active].breakpoint = breakpoint;
        if (breakpoint >= lines[active + 1].breakpoint) count = erase_line(lines, count, active + 1);
        else break;
    }
    if (active + 1 == count) lines[active].breakpoint = BREAKPOINT_INFINITY;
    if (active > 0) {
        long breakpoint = intersection(lines[active - 1], lines[active]);
        lines[active - 1].breakpoint = breakpoint;
        usz cursor;
        if (breakpoint >= lines[active].breakpoint) {
            count = erase_line(lines, count, active);
            active--;
            lines[active].breakpoint = active + 1 < count
                ? intersection(lines[active], lines[active + 1]) : BREAKPOINT_INFINITY;
            cursor = active;
        } else cursor = active - 1;
        while (cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint) {
            count = erase_line(lines, count, cursor);
            cursor--;
            active--;
            lines[cursor].breakpoint = cursor + 1 < count
                ? intersection(lines[cursor], lines[cursor + 1]) : BREAKPOINT_INFINITY;
        }
    }
    return count;
}

fn long line_query(AolcLine* lines, usz count, long x, long objective) {
    usz low = 0, high = count;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (lines[middle].breakpoint < x) low = middle + 1;
        else high = middle;
    }
    return (lines[low].slope * x + lines[low].intercept) * objective;
}

fn long arbitrary_order_line_container(long* input, usz length) @export("arbitrary_order_line_container") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0], operation_value = input[1];
    if ((mode != 0 && mode != 1) || operation_value < 0 || operation_value > (long)MAX_OPERATIONS) return -1;
    usz operations = (usz)operation_value;
    if (length != 2 + 3 * operations) return -1;
    bool seen_line = false;
    for (usz operation = 0; operation < operations; operation++) {
        usz p = 2 + 3 * operation;
        long opcode = input[p], first = input[p + 1], second = input[p + 2];
        if (opcode == 0) {
            if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return -1;
            seen_line = true;
        } else if (opcode == 1) {
            if (!seen_line || first < -1000 || first > 1000 || second != 0) return -1;
        } else return -1;
    }
    long objective = mode == 1 ? 1 : -1;
    AolcLine[MAX_OPERATIONS] lines;
    usz line_count = 0, query_index = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operations; operation++) {
        usz p = 2 + 3 * operation;
        if (input[p] == 0) line_count = insert_line(&lines[0], line_count, input[p + 1] * objective, input[p + 2] * objective);
        else {
            long optimum = line_query(&lines[0], line_count, input[p + 1], objective);
            checksum += (long)(query_index + 1) * (optimum + CHECKSUM_OFFSET);
            query_index++;
        }
    }
    return checksum;
}
