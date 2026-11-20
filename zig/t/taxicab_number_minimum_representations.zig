const MAX_ROOT: usize = 444;
const MAX_ROOT_I32: i32 = 444;
const MAX_PARSEABLE_LENGTH: usize = 2;

const Node = struct {
    sum: i32,
    a: i32,
    b: i32,
};

fn lessNode(left: Node, right: Node) bool {
    if (left.sum != right.sum) return left.sum < right.sum;
    if (left.a != right.a) return left.a < right.a;
    return left.b < right.b;
}

fn push(heap: *[MAX_ROOT]Node, size: *usize, node: Node) void {
    var index = size.*;
    size.* += 1;
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (!lessNode(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

fn pop(heap: *[MAX_ROOT]Node, size: *usize) Node {
    const result = heap[0];
    size.* -= 1;
    if (size.* == 0) return result;
    const last = heap[size.*];
    var index: usize = 0;
    while (2 * index + 1 < size.*) {
        var child = 2 * index + 1;
        if (child + 1 < size.* and lessNode(heap[child + 1], heap[child])) child += 1;
        if (!lessNode(heap[child], last)) break;
        heap[index] = heap[child];
        index = child;
    }
    heap[index] = last;
    return result;
}

fn cube(value: i32) i32 {
    return value * value * value;
}

fn search(ways: i32) i64 {
    var heap: [MAX_ROOT]Node = undefined;
    var size: usize = 0;
    for (1..MAX_ROOT + 1) |raw_a| {
        const a: i32 = @intCast(raw_a);
        const value = cube(a);
        push(&heap, &size, Node{ .sum = 2 * value, .a = a, .b = a });
    }
    while (size > 0) {
        const first = pop(&heap, &size);
        const total = first.sum;
        var count: i32 = 1;
        if (first.b < MAX_ROOT_I32) {
            const next_b = first.b + 1;
            push(&heap, &size, Node{ .sum = cube(first.a) + cube(next_b), .a = first.a, .b = next_b });
        }
        while (size > 0 and heap[0].sum == total) {
            const equal = pop(&heap, &size);
            count += 1;
            if (equal.b < MAX_ROOT_I32) {
                const next_b = equal.b + 1;
                push(&heap, &size, Node{ .sum = cube(equal.a) + cube(next_b), .a = equal.a, .b = next_b });
            }
        }
        if (count >= ways) return @as(i64, total);
    }
    return -1;
}

export fn taxicab_number_minimum_representations(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 or (input[0] != 2 and input[0] != 3)) return -1;
    return search(@intCast(input[0]));
}
