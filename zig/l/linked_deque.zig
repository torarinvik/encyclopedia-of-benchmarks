export fn linked_deque(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 20 or length % 2 != 0) return -1;
    var queue: [40]i64 = @splat(0);
    var head: usize = 16;
    var tail: usize = 16;
    var result: i64 = 0;
    var place: i64 = 1;
    var p: usize = 0;
    while (p < length) : (p += 2) {
        const op = values[p];
        const arg = values[p + 1];
        if (op < 0 or op > 6) return -1;
        if (op < 2) {
            if (arg < -15 or arg > 15) return -1;
            if (op == 0) { head -= 1; queue[head] = arg; }
            else { queue[tail] = arg; tail += 1; }
            continue;
        }
        if (arg != 0) return -1;
        var digit: i64 = 0;
        if (op == 2) {
            if (head < tail) { digit = queue[head] + 16; head += 1; }
        } else if (op == 3) {
            if (head < tail) { tail -= 1; digit = queue[tail] + 16; }
        } else if (op == 4) {
            if (head < tail) digit = queue[head] + 16;
        } else if (op == 5) {
            if (head < tail) digit = queue[tail - 1] + 16;
        } else {
            digit = if (head == tail) 1 else 2;
        }
        result += digit * place;
        place *= 32;
    }
    return result;
}
