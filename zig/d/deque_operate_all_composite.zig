const max_operations: i64 = 64;
const max_input_length: usize = 1 + 3 * 64;
const tree_base: usize = 128;
const tree_nodes: usize = 256;
const modulus: i64 = 998_244_353;

const Affine = struct { a: i64 = 1, b: i64 = 0 };

fn compose(first: Affine, second: Affine) Affine {
    return .{
        .a = @rem(second.a * first.a, modulus),
        .b = @rem(second.a * first.b + second.b, modulus),
    };
}

const AggregateDeque = struct {
    tree: [tree_nodes]Affine = [_]Affine{.{}} ** tree_nodes,
    head: usize = 64,
    tail: usize = 64,

    fn update(self: *AggregateDeque, position: usize, value: Affine) void {
        var node = tree_base + position;
        self.tree[node] = value;
        while (node > 1) {
            node >>= 1;
            self.tree[node] = compose(self.tree[node * 2], self.tree[node * 2 + 1]);
        }
    }
};

export fn deque_operate_all_composite(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > max_input_length) return -1;
    const packed = values.?;
    const operation_value = packed[0];
    if (operation_value < 0 or operation_value > max_operations) return -1;
    const operation_count: usize = @intCast(operation_value);
    var deque = AggregateDeque{};
    var position: usize = 1;
    var checksum: i64 = 0;
    var query_number: i64 = 0;

    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = packed[position];
        position += 1;
        if (opcode == 0 or opcode == 1) {
            if (length - position < 2) return -1;
            const a = packed[position];
            const b = packed[position + 1];
            position += 2;
            if (a < 1 or a >= modulus or b < 0 or b >= modulus) return -1;
            const function = Affine{ .a = a, .b = b };
            if (opcode == 0) {
                if (deque.head == 0) return -1;
                deque.head -= 1;
                deque.update(deque.head, function);
            } else {
                if (deque.tail == tree_base) return -1;
                const tail = deque.tail;
                deque.tail += 1;
                deque.update(tail, function);
            }
        } else if (opcode == 2 or opcode == 3) {
            if (deque.head == deque.tail) return -1;
            if (opcode == 2) {
                const head = deque.head;
                deque.head += 1;
                deque.update(head, Affine{});
            } else {
                deque.tail -= 1;
                deque.update(deque.tail, Affine{});
            }
        } else if (opcode == 4) {
            if (position >= length) return -1;
            const x = packed[position];
            position += 1;
            if (x < 0 or x >= modulus) return -1;
            const function = deque.tree[1];
            const answer = @rem(function.a * x + function.b, modulus);
            query_number += 1;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    return checksum;
}
