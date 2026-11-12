const MAX_N: i64 = 64;
const ENCODING_BASE: i64 = 65;

fn nextNode(input: [*]const i64, node: i64) i64 {
    return input[2 + @as(usize, @intCast(node))];
}

export fn functional_graph_cycle_parameters(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 66) return -1;
    const input = input_opt.?;
    const n = input[0];
    const start = input[1];
    if (n < 1 or n > MAX_N or start < 0 or start >= n or length != @as(usize, @intCast(n + 2))) return -1;
    for (0..@as(usize, @intCast(n))) |i| {
        const successor = input[2 + i];
        if (successor < 0 or successor >= n) return -1;
    }

    var tortoise = nextNode(input, start);
    var hare = nextNode(input, nextNode(input, start));
    while (tortoise != hare) {
        tortoise = nextNode(input, tortoise);
        hare = nextNode(input, nextNode(input, hare));
    }
    var mu: i64 = 0;
    tortoise = start;
    while (tortoise != hare) {
        tortoise = nextNode(input, tortoise);
        hare = nextNode(input, hare);
        mu += 1;
    }
    var lambda: i64 = 1;
    hare = nextNode(input, tortoise);
    while (hare != tortoise) {
        hare = nextNode(input, hare);
        lambda += 1;
    }
    return ENCODING_BASE * mu + lambda;
}
