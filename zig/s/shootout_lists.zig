const LIST_SIZE: usize = 100;
const MIN_RUNS: i64 = 0;
const MAX_RUNS: i64 = 10_000;
const NODE_COUNT: usize = 203;

const ListNode = struct { value: i32, next: usize, prev: usize };

fn initSequence(nodes: *[NODE_COUNT]ListNode, head: usize, base: usize) void {
    nodes[head].value = @intCast(LIST_SIZE);
    nodes[head].next = base;
    nodes[head].prev = base + LIST_SIZE - 1;
    for (0..LIST_SIZE) |offset| {
        const item = base + offset;
        nodes[item].value = @intCast(offset + 1);
        nodes[item].prev = if (offset == 0) head else item - 1;
        nodes[item].next = if (offset + 1 == LIST_SIZE) head else item + 1;
    }
}

fn listLength(nodes: *const [NODE_COUNT]ListNode, head: usize) i32 { return nodes[head].value; }

fn popHead(nodes: *[NODE_COUNT]ListNode, head: usize) ?usize {
    if (listLength(nodes, head) == 0) return null;
    const item = nodes[head].next;
    const next = nodes[item].next;
    nodes[head].next = next;
    nodes[next].prev = head;
    nodes[head].value -= 1;
    return item;
}

fn popTail(nodes: *[NODE_COUNT]ListNode, head: usize) ?usize {
    if (listLength(nodes, head) == 0) return null;
    const item = nodes[head].prev;
    const prev = nodes[item].prev;
    nodes[head].prev = prev;
    nodes[prev].next = head;
    nodes[head].value -= 1;
    return item;
}

fn pushTail(nodes: *[NODE_COUNT]ListNode, head: usize, item: usize) void {
    const tail = nodes[head].prev;
    nodes[tail].next = item;
    nodes[item].next = head;
    nodes[head].prev = item;
    nodes[item].prev = tail;
    nodes[head].value += 1;
}

fn reverseList(nodes: *[NODE_COUNT]ListNode, head: usize) void {
    var current = head;
    while (true) {
        const old_next = nodes[current].next;
        nodes[current].next = nodes[current].prev;
        nodes[current].prev = old_next;
        current = old_next;
        if (current == head) break;
    }
}

fn listsEqual(nodes: *const [NODE_COUNT]ListNode, left: usize, right: usize) bool {
    if (listLength(nodes, left) != listLength(nodes, right)) return false;
    var a = nodes[left].next;
    var b = nodes[right].next;
    while (a != left and b != right) {
        if (nodes[a].value != nodes[b].value) return false;
        a = nodes[a].next;
        b = nodes[b].next;
    }
    return a == left and b == right;
}

fn testLists() bool {
    var nodes: [NODE_COUNT]ListNode = undefined;
    const original: usize = 0;
    const copied: usize = 101;
    const staging: usize = 202;
    initSequence(&nodes, original, 1);
    initSequence(&nodes, copied, 102);
    nodes[staging] = .{ .value = 0, .next = staging, .prev = staging };
    if (!listsEqual(&nodes, copied, original)) return false;
    while (listLength(&nodes, copied) > 0) {
        const item = popHead(&nodes, copied) orelse return false;
        pushTail(&nodes, staging, item);
    }
    if (listLength(&nodes, copied) != 0) return false;
    while (listLength(&nodes, staging) > 0) {
        const item = popTail(&nodes, staging) orelse return false;
        pushTail(&nodes, copied, item);
    }
    if (listLength(&nodes, staging) != 0) return false;
    reverseList(&nodes, original);
    return nodes[nodes[original].next].value == @as(i32, @intCast(LIST_SIZE))
        and nodes[nodes[original].prev].value == 1
        and nodes[nodes[copied].next].value == @as(i32, @intCast(LIST_SIZE))
        and nodes[nodes[copied].prev].value == 1
        and listLength(&nodes, original) == @as(i32, @intCast(LIST_SIZE))
        and listsEqual(&nodes, original, copied);
}

export fn shootout_lists(runs: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (runs < MIN_RUNS or runs > MAX_RUNS) return -1;
    if (output_opt == null) return -2;
    const staged: []const u8 = if (runs == 0) "0\n" else "100\n";
    if (output_capacity < staged.len) return -2;
    for (0..@intCast(runs)) |_| {
        if (!testLists()) return -1;
    }
    const output = output_opt.?;
    for (staged, 0..) |byte, index| output[index] = byte;
    return @intCast(staged.len);
}
