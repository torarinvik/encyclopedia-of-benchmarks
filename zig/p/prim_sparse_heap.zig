const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 4096;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const NONE: usize = MAX_VERTICES;
const NO_ARC: usize = MAX_ARCS;

fn before(best: *const [MAX_VERTICES]i64, left: usize, right: usize) bool {
    return best.*[left] < best.*[right] or
        (best.*[left] == best.*[right] and left < right);
}

fn exchange(heap: *[MAX_VERTICES]usize, position: *[MAX_VERTICES]usize,
            first: usize, second: usize) void {
    const saved = heap.*[first];
    heap.*[first] = heap.*[second];
    heap.*[second] = saved;
    position.*[heap.*[first]] = first;
    position.*[heap.*[second]] = second;
}

fn siftUp(heap: *[MAX_VERTICES]usize, position: *[MAX_VERTICES]usize,
          best: *const [MAX_VERTICES]i64, start: usize) void {
    var at = start;
    while (at > 0) {
        const parent = (at - 1) / 2;
        if (!before(best, heap.*[at], heap.*[parent])) break;
        exchange(heap, position, at, parent);
        at = parent;
    }
}

fn pop(heap: *[MAX_VERTICES]usize, position: *[MAX_VERTICES]usize,
       count: *usize, best: *const [MAX_VERTICES]i64) usize {
    const result = heap.*[0];
    position.*[result] = NONE;
    count.* -= 1;
    if (count.* > 0) {
        heap.*[0] = heap.*[count.*];
        position.*[heap.*[0]] = 0;
        var at: usize = 0;
        while (2 * at + 1 < count.*) {
            var child = 2 * at + 1;
            if (child + 1 < count.* and before(best, heap.*[child + 1], heap.*[child])) child += 1;
            if (!before(best, heap.*[child], heap.*[at])) break;
            exchange(heap, position, at, child);
            at = child;
        }
    }
    return result;
}

export fn prim_sparse_heap(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 2 + 3 * MAX_EDGES) return -2;
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 4096) return -2;
    const vertices: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    if (length != 2 + 3 * edge_count or (vertices == 0 and edge_count != 0)) return -2;
    if (vertices == 0) return 0;
    for (0..edge_count) |edge| {
        const origin = values[2 + 3 * edge];
        const destination = values[3 + 3 * edge];
        const weight = values[4 + 3 * edge];
        if (origin < 0 or destination < 0 or origin >= @as(i64, @intCast(vertices)) or
            destination >= @as(i64, @intCast(vertices)) or weight < 0 or weight > 2147483647) return -2;
    }

    var head: [MAX_VERTICES]usize = @splat(NO_ARC);
    var next: [MAX_ARCS]usize = undefined;
    var to: [MAX_ARCS]usize = undefined;
    var arc_weight: [MAX_ARCS]i64 = undefined;
    var arc_count: usize = 0;
    for (0..edge_count) |edge| {
        const origin: usize = @intCast(values[2 + 3 * edge]);
        const destination: usize = @intCast(values[3 + 3 * edge]);
        const weight = values[4 + 3 * edge];
        if (origin == destination) continue;
        to[arc_count] = destination;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[origin];
        head[origin] = arc_count;
        arc_count += 1;
        to[arc_count] = origin;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[destination];
        head[destination] = arc_count;
        arc_count += 1;
    }

    var best: [MAX_VERTICES]i64 = @splat(0);
    var has_best: [MAX_VERTICES]bool = @splat(false);
    var selected: [MAX_VERTICES]bool = @splat(false);
    var heap: [MAX_VERTICES]usize = @splat(0);
    var position: [MAX_VERTICES]usize = @splat(NONE);
    var heap_count: usize = 1;
    var selected_count: usize = 0;
    var total: i64 = 0;
    heap[0] = 0;
    position[0] = 0;
    has_best[0] = true;

    while (heap_count > 0) {
        const origin = pop(&heap, &position, &heap_count, &best);
        selected[origin] = true;
        selected_count += 1;
        total += best[origin];
        var arc = head[origin];
        while (arc != NO_ARC) : (arc = next[arc]) {
            const destination = to[arc];
            const weight = arc_weight[arc];
            if (!selected[destination] and (!has_best[destination] or weight < best[destination])) {
                best[destination] = weight;
                has_best[destination] = true;
                if (position[destination] == NONE) {
                    heap[heap_count] = destination;
                    position[destination] = heap_count;
                    heap_count += 1;
                }
                siftUp(&heap, &position, &best, position[destination]);
            }
        }
    }
    return if (selected_count == vertices) total else -1;
}
