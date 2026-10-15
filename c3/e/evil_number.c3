module evil_number;

fn long evil_number(long value) @export("evil_number") {
    if (value < 0) return -1;
    long count = 0;
    while (value > 0) {
        count += value & 1;
        value >>= 1;
    }
    return count % 2 == 0 ? 1 : 0;
}
