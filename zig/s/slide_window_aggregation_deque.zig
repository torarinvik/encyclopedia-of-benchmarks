const max_operations: usize = 32;
const max_input_length: usize = 162;
const modulus: i64 = 97;

const Matrix = struct { a: i64 = 0, b: i64 = 0, c: i64 = 0, d: i64 = 0 };
const identity = Matrix{ .a = 1, .b = 0, .c = 0, .d = 1 };

fn multiply(x: Matrix, y: Matrix) Matrix {
    return .{
        .a = @rem(x.a * y.a + x.b * y.c, modulus),
        .b = @rem(x.a * y.b + x.b * y.d, modulus),
        .c = @rem(x.c * y.a + x.d * y.c, modulus),
        .d = @rem(x.c * y.b + x.d * y.d, modulus),
    };
}

fn pack(value: Matrix) i64 {
    return value.a + modulus * value.b + modulus * modulus * value.c
        + modulus * modulus * modulus * value.d;
}

fn pushFront(items: *[max_operations]Matrix, aggregates: *[max_operations]Matrix,
             count: *usize, value: Matrix) void {
    items[count.*] = value;
    aggregates[count.*] = if (count.* == 0) value else multiply(value, aggregates[count.* - 1]);
    count.* += 1;
}

fn pushBack(items: *[max_operations]Matrix, aggregates: *[max_operations]Matrix,
            count: *usize, value: Matrix) void {
    items[count.*] = value;
    aggregates[count.*] = if (count.* == 0) value else multiply(aggregates[count.* - 1], value);
    count.* += 1;
}

fn rebalance(front: *[max_operations]Matrix, front_aggregates: *[max_operations]Matrix,
             front_count: *usize, back: *[max_operations]Matrix,
             back_aggregates: *[max_operations]Matrix, back_count: *usize,
             temporary: *[max_operations]Matrix) void {
    const front_was_empty = front_count.* == 0;
    const total = front_count.* + back_count.*;
    for (0..front_count.*) |i| temporary[i] = front[front_count.* - 1 - i];
    for (0..back_count.*) |i| temporary[front_count.* + i] = back[i];
    const front_size = total / 2 + (if (front_was_empty) total % 2 else 0);
    front_count.* = 0;
    back_count.* = 0;
    var i = front_size;
    while (i > 0) {
        i -= 1;
        pushFront(front, front_aggregates, front_count, temporary[i]);
    }
    for (front_size..total) |index| pushBack(back, back_aggregates, back_count, temporary[index]);
}

export fn slide_window_aggregation_deque(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > max_input_length) return -1;
    const input = values.?;
    if (input[0] < 0 or input[0] > max_operations) return -1;
    const operation_count: usize = @intCast(input[0]);
    var front = [_]Matrix{identity} ** max_operations;
    var front_aggregates = [_]Matrix{identity} ** max_operations;
    var back = [_]Matrix{identity} ** max_operations;
    var back_aggregates = [_]Matrix{identity} ** max_operations;
    var temporary = [_]Matrix{identity} ** max_operations;
    var front_count: usize = 0;
    var back_count: usize = 0;
    var position: usize = 1;
    var query_ordinal: i64 = 0;
    var checksum: i64 = 0;

    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = input[position];
        position += 1;
        if (opcode == 0 or opcode == 1) {
            if (length - position < 4) return -1;
            const value = Matrix{ .a = input[position], .b = input[position + 1],
                                  .c = input[position + 2], .d = input[position + 3] };
            if (value.a < 0 or value.a >= modulus or value.b < 0 or value.b >= modulus or
                value.c < 0 or value.c >= modulus or value.d < 0 or value.d >= modulus) return -1;
            position += 4;
            if (opcode == 0) pushFront(&front, &front_aggregates, &front_count, value)
            else pushBack(&back, &back_aggregates, &back_count, value);
        } else if (opcode == 2 or opcode == 3) {
            if (front_count + back_count == 0) return -1;
            if (opcode == 2) {
                if (front_count == 0) rebalance(&front, &front_aggregates, &front_count,
                                                &back, &back_aggregates, &back_count, &temporary);
                front_count -= 1;
            } else {
                if (back_count == 0) rebalance(&front, &front_aggregates, &front_count,
                                               &back, &back_aggregates, &back_count, &temporary);
                back_count -= 1;
            }
        } else if (opcode == 4) {
            const left = if (front_count == 0) identity else front_aggregates[front_count - 1];
            const right = if (back_count == 0) identity else back_aggregates[back_count - 1];
            query_ordinal += 1;
            checksum += query_ordinal * (pack(multiply(left, right)) + 1);
        } else return -1;
    }
    if (position != length) return -1;
    return checksum;
}
