const max_operations: i64 = 64;
const max_input_length: usize = 1 + 3 * 64;
const modulus: i64 = 998_244_353;

const Affine = struct { a: i64 = 1, b: i64 = 0 };
const Queue = struct {
    back_functions: [64]Affine = [_]Affine{.{}} ** 64,
    back_aggregates: [64]Affine = [_]Affine{.{}} ** 64,
    front_aggregates: [64]Affine = [_]Affine{.{}} ** 64,
    back_size: usize = 0,
    front_size: usize = 0,

    fn pushBack(self: *Queue, a: i64, b: i64) void {
        const function = Affine{ .a = a, .b = b };
        self.back_functions[self.back_size] = function;
        self.back_aggregates[self.back_size] = if (self.back_size == 0)
            function
        else
            compose(self.back_aggregates[self.back_size - 1], function);
        self.back_size += 1;
    }

    fn transfer(self: *Queue) void {
        while (self.back_size > 0) {
            self.back_size -= 1;
            const function = self.back_functions[self.back_size];
            self.front_aggregates[self.front_size] = if (self.front_size == 0)
                function
            else
                compose(function, self.front_aggregates[self.front_size - 1]);
            self.front_size += 1;
        }
    }

    fn popFront(self: *Queue) bool {
        if (self.front_size == 0) self.transfer();
        if (self.front_size == 0) return false;
        self.front_size -= 1;
        return true;
    }

    fn aggregate(self: *const Queue) Affine {
        var result = Affine{};
        if (self.front_size > 0) result = self.front_aggregates[self.front_size - 1];
        if (self.back_size > 0) {
            result = if (self.front_size > 0)
                compose(result, self.back_aggregates[self.back_size - 1])
            else
                self.back_aggregates[self.back_size - 1];
        }
        return result;
    }
};

fn compose(first: Affine, second: Affine) Affine {
    return .{
        .a = (second.a * first.a) % modulus,
        .b = (second.a * first.b + second.b) % modulus,
    };
}

export fn queue_operate_all_composite(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > max_input_length) return -1;
    const packed = values.?;
    const operation_value = packed[0];
    if (operation_value < 0 or operation_value > max_operations) return -1;
    const operation_count: usize = @intCast(operation_value);
    var queue = Queue{};
    var position: usize = 1;
    var checksum: i64 = 0;
    var query_number: i64 = 0;
    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = packed[position];
        position += 1;
        if (opcode == 0) {
            if (length - position < 2) return -1;
            const a = packed[position];
            const b = packed[position + 1];
            position += 2;
            if (a < 1 or a >= modulus or b < 0 or b >= modulus) return -1;
            queue.pushBack(a, b);
        } else if (opcode == 1) {
            if (!queue.popFront()) return -1;
        } else if (opcode == 2) {
            if (position >= length) return -1;
            const x = packed[position];
            position += 1;
            if (x < 0 or x >= modulus) return -1;
            const function = queue.aggregate();
            const answer = (function.a * x + function.b) % modulus;
            query_number += 1;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    return checksum;
}
