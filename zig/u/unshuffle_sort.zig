const MAX_ITEMS: usize = 1024;
const NONE: u32 = MAX_ITEMS;
const NodeTable = [MAX_ITEMS]u32;

fn pileLess(values: []const i64, pile_front: *const NodeTable, left: u32, right: u32) bool {
    const left_node: usize = pile_front.*[@intCast(left)];
    const right_node: usize = pile_front.*[@intCast(right)];
    if (values[left_node] != values[right_node]) return values[left_node] < values[right_node];
    return left < right;
}

fn siftDown(values: []const i64, pile_front: *const NodeTable, heap: *NodeTable,
            heap_size: usize, start: usize) void {
    var position = start;
    while (position * 2 + 1 < heap_size) {
        var child = position * 2 + 1;
        if (child + 1 < heap_size and pileLess(values, pile_front,
                heap.*[child + 1], heap.*[child])) child += 1;
        if (!pileLess(values, pile_front, heap.*[child], heap.*[position])) break;
        const temporary = heap.*[position];
        heap.*[position] = heap.*[child];
        heap.*[child] = temporary;
        position = child;
    }
}

pub export fn unshuffle_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2 or length > MAX_ITEMS) return;
    const input_values = values[0..length];
    const output_values = scratch[0..length];
    var previous: NodeTable = @splat(0);
    var next: NodeTable = @splat(0);
    var pile_front: NodeTable = @splat(0);
    var pile_back: NodeTable = @splat(0);
    var heap: NodeTable = @splat(0);
    var pile_count: usize = 0;

    for (0..length) |node| {
        previous[node] = NONE;
        next[node] = NONE;
        var pile: usize = 0;
        while (pile < pile_count) {
            const front: usize = pile_front[pile];
            const back: usize = pile_back[pile];
            if (input_values[node] <= input_values[front]) {
                next[node] = @intCast(front);
                previous[front] = @intCast(node);
                pile_front[pile] = @intCast(node);
                break;
            }
            if (input_values[node] >= input_values[back]) {
                previous[node] = @intCast(back);
                next[back] = @intCast(node);
                pile_back[pile] = @intCast(node);
                break;
            }
            pile += 1;
        }
        if (pile == pile_count) {
            pile_front[pile_count] = @intCast(node);
            pile_back[pile_count] = @intCast(node);
            pile_count += 1;
        }
    }

    var heap_size: usize = 0;
    for (0..pile_count) |pile| {
        var position = heap_size;
        heap[position] = @intCast(pile);
        heap_size += 1;
        while (position > 0) {
            const parent = (position - 1) / 2;
            if (!pileLess(input_values, &pile_front, heap[position], heap[parent])) break;
            const temporary = heap[position];
            heap[position] = heap[parent];
            heap[parent] = temporary;
            position = parent;
        }
    }

    var output: usize = 0;
    while (heap_size > 0) {
        const pile_id = heap[0];
        const pile: usize = @intCast(pile_id);
        const node: usize = pile_front[pile];
        output_values[output] = input_values[node];
        output += 1;
        const successor = next[node];
        if (successor != NONE) {
            previous[@intCast(successor)] = NONE;
            next[node] = NONE;
            pile_front[pile] = successor;
        } else {
            pile_front[pile] = NONE;
            pile_back[pile] = NONE;
            heap_size -= 1;
            if (heap_size > 0) heap[0] = heap[heap_size];
        }
        if (heap_size > 0) siftDown(input_values, &pile_front, &heap, heap_size, 0);
    }
    @memcpy(values[0..length], output_values);
}
