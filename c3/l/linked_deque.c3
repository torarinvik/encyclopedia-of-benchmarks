module linked_deque;

fn long linked_deque(long* values, usz length) @export("linked_deque") {
    if (values == null || length < 2 || length > 20 || length % 2 != 0) { return -1; }
    long[40] queue = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    usz head = 16;
    usz tail = 16;
    long result = 0;
    long place = 1;
    for (usz p = 0; p < length; p += 2) {
        long op = values[p];
        long arg = values[p + 1];
        if (op < 0 || op > 6) { return -1; }
        if (op < 2) {
            if (arg < -15 || arg > 15) { return -1; }
            if (op == 0) { head--; queue[head] = arg; }
            else { queue[tail] = arg; tail++; }
            continue;
        }
        if (arg != 0) { return -1; }
        long digit = 0;
        if (op == 2) { if (head < tail) { digit = queue[head] + 16; head++; } }
        else if (op == 3) { if (head < tail) { tail--; digit = queue[tail] + 16; } }
        else if (op == 4) { if (head < tail) { digit = queue[head] + 16; } }
        else if (op == 5) { if (head < tail) { digit = queue[tail - 1] + 16; } }
        else { digit = head == tail ? 1 : 2; }
        result += digit * place;
        place *= 32;
    }
    return result;
}
