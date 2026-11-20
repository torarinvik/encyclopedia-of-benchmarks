const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_HEAP: usize = MAX_EDGES + 1;
const NONE: usize = MAX_EDGES;
const HeapEntry = struct { distance: i64, vertex: usize };

fn before(left_distance: i64, left_vertex: usize, right_distance: i64, right_vertex: usize) bool {
    return left_distance < right_distance or
        (left_distance == right_distance and left_vertex < right_vertex);
}

fn push(heap_distance: *[MAX_HEAP]i64, heap_vertex: *[MAX_HEAP]usize,
        count: *usize, distance: i64, vertex: usize) void {
    var position = count.*;
    count.* += 1;
    while (position > 0) {
        const parent = (position - 1) / 2;
        if (!before(distance, vertex, heap_distance.*[parent], heap_vertex.*[parent])) break;
        heap_distance.*[position] = heap_distance.*[parent];
        heap_vertex.*[position] = heap_vertex.*[parent];
        position = parent;
    }
    heap_distance.*[position] = distance;
    heap_vertex.*[position] = vertex;
}

fn pop(heap_distance: *[MAX_HEAP]i64, heap_vertex: *[MAX_HEAP]usize,
       count: *usize) HeapEntry {
    const result = HeapEntry{ .distance = heap_distance.*[0], .vertex = heap_vertex.*[0] };
    count.* -= 1;
    if (count.* > 0) {
        const last_distance = heap_distance.*[count.*];
        const last_vertex = heap_vertex.*[count.*];
        var position: usize = 0;
        while (2 * position + 1 < count.*) {
            var child = 2 * position + 1;
            if (child + 1 < count.* and before(heap_distance.*[child + 1], heap_vertex.*[child + 1],
                                               heap_distance.*[child], heap_vertex.*[child])) child += 1;
            if (!before(heap_distance.*[child], heap_vertex.*[child], last_distance, last_vertex)) break;
            heap_distance.*[position] = heap_distance.*[child];
            heap_vertex.*[position] = heap_vertex.*[child];
            position = child;
        }
        heap_distance.*[position] = last_distance;
        heap_vertex.*[position] = last_vertex;
    }
    return result;
}

export fn dijkstra_lazy_heap(edges: [*]const i64, vertices: usize, edge_count: usize,
                             source: usize, distances: [*]i64, reachable: [*]u8) i64 {
    if (vertices > MAX_VERTICES or edge_count > MAX_EDGES) return -3;
    if (vertices == 0) return if (source == 0 and edge_count == 0) 0 else -3;
    if (source >= vertices) return -3;
    for (0..edge_count) |edge| {
        const origin = edges[3 * edge];
        const destination = edges[3 * edge + 1];
        const weight = edges[3 * edge + 2];
        if (origin < 0 or destination < 0 or @as(u64, @intCast(origin)) >= vertices or
            @as(u64, @intCast(destination)) >= vertices) return -3;
        if (weight < 0) return -4;
    }

    var head: [MAX_VERTICES]usize = @splat(NONE);
    var tail: [MAX_VERTICES]usize = @splat(NONE);
    var next: [MAX_EDGES]usize = @splat(NONE);
    for (0..edge_count) |edge| {
        const origin: usize = @intCast(edges[3 * edge]);
        if (head[origin] == NONE) head[origin] = edge else next[tail[origin]] = edge;
        tail[origin] = edge;
    }

    for (0..vertices) |vertex| {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    var heap_distance: [MAX_HEAP]i64 = @splat(0);
    var heap_vertex: [MAX_HEAP]usize = @splat(0);
    var heap_count: usize = 0;
    distances[source] = 0;
    reachable[source] = 1;
    push(&heap_distance, &heap_vertex, &heap_count, 0, source);

    while (heap_count > 0) {
        const entry = pop(&heap_distance, &heap_vertex, &heap_count);
        const current = entry.distance;
        const origin = entry.vertex;
        if (current != distances[origin] or reachable[origin] == 2) continue;
        reachable[origin] = 2;
        var edge = head[origin];
        while (edge != NONE) : (edge = next[edge]) {
            const destination: usize = @intCast(edges[3 * edge + 1]);
            const weight = edges[3 * edge + 2];
            if (current > 9223372036854775807 - weight) return -2;
            const candidate = current + weight;
            if (reachable[destination] != 2 and
                (reachable[destination] == 0 or candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
                push(&heap_distance, &heap_vertex, &heap_count, candidate, destination);
            }
        }
    }
    for (0..vertices) |vertex| if (reachable[vertex] == 2) { reachable[vertex] = 1; };
    return 0;
}
