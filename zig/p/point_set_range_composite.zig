const modulus: i64 = 998244353;
const max_n: i64 = 16;
const max_operations: i64 = 32;
const max_input_length: usize = 162;
const tree_capacity: usize = 64;

const AffineMap = struct { a: i64 = 1, b: i64 = 0 };

fn compose(left: AffineMap, right: AffineMap) AffineMap {
    return .{
        .a = @mod(right.a * left.a, modulus),
        .b = @mod(right.a * left.b + right.b, modulus),
    };
}

export fn point_set_range_composite(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > max_input_length) return -1;
    const packed = values.?;
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > max_n or q_value < 0 or q_value > max_operations) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + 2 * n + 4 * q) return -1;

    for (0..n) |index| {
        const a = packed[2 + 2 * index];
        const b = packed[3 + 2 * index];
        if (a < 0 or a >= modulus or b < 0 or b >= modulus) return -1;
    }

    var base: usize = 1;
    while (base < n) base *= 2;
    var tree = [_]AffineMap{.{}} ** tree_capacity;
    for (0..n) |index| {
        tree[base + index] = .{ .a = packed[2 + 2 * index], .b = packed[3 + 2 * index] };
    }
    var node = base;
    while (node > 1) {
        node -= 1;
        tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
    }

    var checksum: i64 = 0;
    var query_number: i64 = 0;
    var cursor: usize = 2 + 2 * n;
    for (0..q) |_| {
        const opcode = packed[cursor];
        const first = packed[cursor + 1];
        const second = packed[cursor + 2];
        const third = packed[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 or first >= n_value or second < 0 or second >= modulus or
                third < 0 or third >= modulus) return -1;
            var update_node = base + @as(usize, @intCast(first));
            tree[update_node] = .{ .a = second, .b = third };
            while (update_node > 1) {
                update_node /= 2;
                tree[update_node] = compose(tree[2 * update_node], tree[2 * update_node + 1]);
            }
        } else if (opcode == 1) {
            if (first < 0 or first > second or second > n_value or third < 0 or third >= modulus) return -1;
            var left_index = base + @as(usize, @intCast(first));
            var right_index = base + @as(usize, @intCast(second));
            var left = AffineMap{};
            var right = AffineMap{};
            while (left_index < right_index) {
                if (left_index & 1 == 1) {
                    left = compose(left, tree[left_index]);
                    left_index += 1;
                }
                if (right_index & 1 == 1) {
                    right_index -= 1;
                    right = compose(tree[right_index], right);
                }
                left_index /= 2;
                right_index /= 2;
            }
            const combined = compose(left, right);
            const answer = @mod(combined.a * third + combined.b, modulus);
            query_number += 1;
            checksum = @mod(checksum + query_number * answer, modulus);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;
    return checksum;
}
