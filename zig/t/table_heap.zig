const MAX_ITEMS: usize = 64;
const MAX_OPS: usize = 256;
const MAP_CAPACITY: usize = 128;
const NIL: i64 = -9_223_372_036_854_775_808;
const Entry = struct { id: i32 = 0, priority: i32 = 0, index: usize = 0, state: u8 = 0 };

fn mapHash(id: i32) usize {
    const bits: u32 = @bitCast(id);
    return @as(usize, bits *% 2_654_435_761) & (MAP_CAPACITY - 1);
}
fn mapFind(map: *const [MAP_CAPACITY]Entry, id: i32) usize {
    var slot = mapHash(id);
    for (0..MAP_CAPACITY) |_| {
        if (map[slot].state == 0) return MAP_CAPACITY;
        if (map[slot].state == 1 and map[slot].id == id) return slot;
        slot = (slot + 1) & (MAP_CAPACITY - 1);
    }
    return MAP_CAPACITY;
}
fn mapInsert(map: *[MAP_CAPACITY]Entry, id: i32, priority: i32, index: usize) usize {
    var slot = mapHash(id); var tombstone = MAP_CAPACITY;
    for (0..MAP_CAPACITY) |_| {
        if (map[slot].state == 2 and tombstone == MAP_CAPACITY) tombstone = slot;
        if (map[slot].state == 0) {
            if (tombstone != MAP_CAPACITY) slot = tombstone;
            map[slot] = .{ .id = id, .priority = priority, .index = index, .state = 1 }; return slot;
        }
        if (map[slot].state == 1 and map[slot].id == id) return slot;
        slot = (slot + 1) & (MAP_CAPACITY - 1);
    }
    if (tombstone != MAP_CAPACITY) { map[tombstone] = .{ .id = id, .priority = priority, .index = index, .state = 1 }; return tombstone; }
    return MAP_CAPACITY;
}
fn mapRemove(map: *[MAP_CAPACITY]Entry, slot: usize) void { map[slot].state = 2; }
fn swap(heap: *[MAX_ITEMS]i32, map: *[MAP_CAPACITY]Entry, a: usize, b: usize, update: bool) void {
    const value = heap[a]; heap[a] = heap[b]; heap[b] = value;
    if (update) { map[mapFind(map, heap[a])].index = a; map[mapFind(map, heap[b])].index = b; }
}
fn down(heap: *[MAX_ITEMS]i32, count: usize, map: *[MAP_CAPACITY]Entry, start: usize, update: bool) void {
    var index = start;
    while (true) {
        const left = index * 2 + 1; if (left >= count) return;
        var child = left + 1;
        if (child >= count or map[mapFind(map, heap[left])].priority < map[mapFind(map, heap[child])].priority) child = left;
        if (map[mapFind(map, heap[child])].priority >= map[mapFind(map, heap[index])].priority) return;
        swap(heap, map, index, child, update); index = child;
    }
}
fn up(heap: *[MAX_ITEMS]i32, map: *[MAP_CAPACITY]Entry, start: usize) void {
    var index = start;
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (map[mapFind(map, heap[index])].priority >= map[mapFind(map, heap[parent])].priority) return;
        swap(heap, map, index, parent, true); index = parent;
    }
}
fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn table_heap(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 1155) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_ITEMS) return -1;
    const initial: usize = @intCast(input[0]); const op_index = 1 + 2 * initial;
    if (length <= op_index or input[op_index] < 0 or input[op_index] > MAX_OPS) return -1;
    const op_count: usize = @intCast(input[op_index]);
    if (length != 2 + 2 * initial + 4 * op_count or length > 1154) return -1;
    var heap: [MAX_ITEMS]i32 = @splat(0); var map: [MAP_CAPACITY]Entry = @splat(.{}); var count = initial;
    for (0..initial) |i| {
        const id = input[1 + 2 * i]; const p = input[2 + 2 * i];
        if (id < -2147483648 or id > 2147483647 or p < -2147483648 or p > 2147483647) return -1;
        const item: i32 = @intCast(id); if (mapFind(&map, item) != MAP_CAPACITY) return -1;
        heap[i] = item; _ = mapInsert(&map, item, @intCast(p), 0);
    }
    var parent = count / 2;
    while (parent > 0) { parent -= 1; down(&heap, count, &map, parent, false); }
    for (0..count) |i| map[mapFind(&map, heap[i])].index = i;

    var answers: [MAX_OPS]i64 = @splat(0); var cursor = op_index + 1;
    for (0..op_count) |oi| {
        const op = input[cursor]; const a = input[cursor + 1]; const b = input[cursor + 2]; const c = input[cursor + 3]; cursor += 4;
        if (op < 0 or op > 9) return -1;
        if (op == 0) {
            if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647 or c != 0 or count == MAX_ITEMS) return -1;
            const id: i32 = @intCast(a); if (mapFind(&map, id) != MAP_CAPACITY) return -1;
            heap[count] = id; _ = mapInsert(&map, id, @intCast(b), count); count += 1; up(&heap, &map, count - 1); answers[oi] = NIL;
        } else if (op == 1) {
            if (a != 0 or b != 0 or c != 0) return -1; answers[oi] = if (count == 0) NIL else heap[0];
        } else if (op == 2) {
            if (a != 0 or b != 0 or c != 0 or count == 0) return -1;
            const removed = heap[0]; const slot = mapFind(&map, removed); answers[oi] = removed;
            swap(&heap, &map, 0, count - 1, true); count -= 1; mapRemove(&map, slot);
            if (count > 0) down(&heap, count, &map, 0, true);
        } else if (op == 3 or op == 4) {
            if (a != 0 or b != 0 or c != 0) return -1; answers[oi] = if (op == 3) @intCast(count) else if (count == 0) 1 else 0;
        } else if (op == 5) {
            if (a < -2147483648 or a > 2147483647 or b != 0 or c != 0) return -1;
            const slot = mapFind(&map, @intCast(a)); answers[oi] = if (slot == MAP_CAPACITY) NIL else @intCast(map[slot].index + 1);
        } else if (op == 6 or op == 7) {
            if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647 or c != 0) return -1;
            const slot = mapFind(&map, @intCast(a)); if (slot == MAP_CAPACITY) return -1;
            if ((op == 6 and b > map[slot].priority) or (op == 7 and b < map[slot].priority)) return -1;
            const position = map[slot].index; map[slot].priority = @intCast(b);
            if (op == 6) up(&heap, &map, position) else down(&heap, count, &map, position, true); answers[oi] = NIL;
        } else if (op == 8) {
            if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647 or c < -2147483648 or c > 2147483647) return -1;
            const old_slot = mapFind(&map, @intCast(a)); const new_slot = mapFind(&map, @intCast(b));
            if (old_slot == MAP_CAPACITY or (new_slot != MAP_CAPACITY and (a != b or c != map[old_slot].priority))) return -1;
            if (new_slot == MAP_CAPACITY) {
                const position = map[old_slot].index; const old_priority = map[old_slot].priority; mapRemove(&map, old_slot);
                const new_id: i32 = @intCast(b); _ = mapInsert(&map, new_id, @intCast(c), position); heap[position] = new_id;
                if (c < old_priority) up(&heap, &map, position) else down(&heap, count, &map, position, true);
            }
            answers[oi] = NIL;
        } else {
            if (a < -2147483648 or a > 2147483647 or b != 0 or c != 0) return -1;
            const slot = mapFind(&map, @intCast(a)); if (slot == MAP_CAPACITY) return -1;
            const position = map[slot].index; const old_priority = map[slot].priority; count -= 1;
            if (position != count) {
                heap[position] = heap[count]; map[mapFind(&map, heap[position])].index = position;
                if (map[mapFind(&map, heap[position])].priority < old_priority) up(&heap, &map, position) else down(&heap, count, &map, position, true);
            }
            mapRemove(&map, slot); answers[oi] = NIL;
        }
    }
    const output_bytes = op_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?; for (0..op_count) |i| storeI64(output, i * 8, answers[i]);
    return @intCast(output_bytes);
}
