module grow_only_set;

fn long grow_only_set(long* values, usz length) @export("grow_only_set") {
    if (values == null || length < 1 || length > 25) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > 12 || length != 1 + 2 * (usz)count_value) return -1;
    ulong left = 0, right = 0, answers = 0;
    int query_count = 0;
    for (int index = 0; index < (int)count_value; index++) {
        long opcode = values[1 + 2 * (usz)index], argument = values[2 + 2 * (usz)index];
        if (opcode < 0 || opcode > 7) return -1;
        if (opcode <= 3) {
            if (argument < 0 || argument > 15) return -1;
        } else if (argument != 0) return -1;
        ulong bit = opcode <= 3 ? ((ulong)1 << (usz)argument) : 0;
        if (opcode == 0) left |= bit;
        else if (opcode == 1) right |= bit;
        else if (opcode == 2 || opcode == 3) {
            ulong set = opcode == 2 ? left : right;
            if ((set & bit) != 0) answers |= (ulong)1 << query_count;
            query_count++;
        } else if (opcode == 4) {
            if ((left & right) == left) answers |= (ulong)1 << query_count;
            query_count++;
        } else if (opcode == 5) {
            if ((left & right) == right) answers |= (ulong)1 << query_count;
            query_count++;
        } else if (opcode == 6) left |= right;
        else right |= left;
    }
    return (long)(answers | (left << 12) | (right << 28) | ((ulong)query_count << 44));
}
