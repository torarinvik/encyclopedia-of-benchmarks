module interval_container;

const usz MAX_OPERATIONS = 24;
const usz RECORD_WIDTH = 3;
const usz MAX_INPUT_VALUES = 73;
const usz MAX_INTERVALS = 25;
const long DOMAIN_END = 32;

struct Interval {
    long left;
    long right;
}

fn void add_interval(Interval* items, long* count, long left, long right) {
    if (left == right) return;
    Interval[MAX_INTERVALS] next;
    long out = 0;
    bool inserted = false;
    for (long i = 0; i < *count; i++) {
        Interval current = items[i];
        if (current.right < left) next[out++] = current;
        else if (right < current.left) {
            if (!inserted) {
                next[out++] = {left, right};
                inserted = true;
            }
            next[out++] = current;
        } else {
            if (current.left < left) left = current.left;
            if (current.right > right) right = current.right;
        }
    }
    if (!inserted) next[out++] = {left, right};
    for (long i = 0; i < out; i++) items[i] = next[i];
    *count = out;
}

fn void remove_interval(Interval* items, long* count, long left, long right) {
    if (left == right) return;
    Interval[MAX_INTERVALS + 1] next;
    long out = 0;
    for (long i = 0; i < *count; i++) {
        Interval current = items[i];
        if (current.right <= left || current.left >= right) next[out++] = current;
        else {
            if (current.left < left) next[out++] = {current.left, left};
            if (current.right > right) next[out++] = {right, current.right};
        }
    }
    for (long i = 0; i < out; i++) items[i] = next[i];
    *count = out;
}

fn long covered_length(Interval* items, long count) {
    long total = 0;
    for (long i = 0; i < count; i++) total += items[i].right - items[i].left;
    total
}

fn bool valid_input(long* input, usz length, long* operation_count) {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return false;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS.long()) return false;
    *operation_count = input[0];
    if (length != 1 + operation_count.usz() * RECORD_WIDTH) return false;
    for (long i = 0; i < *operation_count; i++) {
        usz offset = 1 + i.usz() * RECORD_WIDTH;
        long opcode = input[offset], left = input[offset + 1], right = input[offset + 2];
        if (opcode < 0 || opcode > 1 || left < 0 || right < left || right > DOMAIN_END)
            return false;
    }
    true
}

fn long interval_container(long* input, usz length) @export("interval_container") {
    long operation_count = 0;
    if (!valid_input(input, length, &operation_count)) return -1;
    Interval[MAX_INTERVALS] items;
    for (usz i = 0; i < MAX_INTERVALS; i++) {
        items[i].left = 0;
        items[i].right = 0;
    }
    long count = 0, checksum = 0;
    for (long i = 0; i < operation_count; i++) {
        usz offset = 1 + i.usz() * RECORD_WIDTH;
        long opcode = input[offset], left = input[offset + 1], right = input[offset + 2];
        if (opcode == 0) add_interval(items, &count, left, right);
        else remove_interval(items, &count, left, right);
        checksum += (i + 1) * covered_length(items, count);
    }
    checksum
}
