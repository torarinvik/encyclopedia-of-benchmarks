const MAX_Q: usize = 512;
const MAX_INPUT: usize = 1025;
const CHECKSUM_OFFSET: i64 = 128;

export fn queue_using_array(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT) return -1;
    const input = packed orelse return -1;
    const qv = input[0];
    if (qv < 0 or qv > @as(i64, @intCast(MAX_Q)) or length != 1 + @as(usize, @intCast(qv)) * 2) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const value = input[2 + i * 2];
        if (op == 0) { if (value < -128 or value > 127) return -1; }
        else if (op == 1) { if (value != 0) return -1; }
        else return -1;
    }
    var values: [10]i16 = @splat(0);
    var front: i32 = -1;
    var rear: i32 = -1;
    var checksum: i64 = 0;
    var ordinal: i64 = 0;
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const value = input[2 + i * 2];
        if (op == 0) {
            if (rear == 9) continue;
            if (front == -1 and rear == -1) { front = 0; rear = 0; values[0] = @intCast(value); }
            else if (rear < 10) { rear += 1; values[@intCast(rear)] = @intCast(value); }
        } else {
            var dequeued: i64 = 0;
            if (front != -1) {
                if (front == rear) { dequeued = @intCast(values[@intCast(front)]); front = -1; rear = -1; }
                else { dequeued = @intCast(values[@intCast(front)]); front += 1; }
            }
            ordinal += 1;
            checksum += ordinal * (dequeued + CHECKSUM_OFFSET);
        }
    }
    return checksum;
}
