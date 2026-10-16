const MAX_OPERATIONS: usize = 512;
const MAX_ITEMS: usize = 128;
const ID_CAPACITY: usize = 4096;
const MAX_INPUT_LENGTH: usize = 1537;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashByte(hash: u64, byte: u8) u64 {
    return (hash ^ byte) *% FNV_PRIME;
}

fn hashI32(hash0: u64, value: i64) u64 {
    var hash = hash0;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    inline for (0..4) |index| hash = hashByte(hash, @truncate(bits >> @as(u5, @intCast(index * 8))));
    return hash;
}

fn swapItems(ids: *[MAX_ITEMS]i64, priorities: *[MAX_ITEMS]i64,
             positions: *[ID_CAPACITY]i32, first: usize, second: usize) void {
    const id = ids[first]; ids[first] = ids[second]; ids[second] = id;
    const priority = priorities[first]; priorities[first] = priorities[second]; priorities[second] = priority;
    positions[@intCast(ids[first])] = @intCast(first);
    positions[@intCast(ids[second])] = @intCast(second);
}

fn heapifyUp(ids: *[MAX_ITEMS]i64, priorities: *[MAX_ITEMS]i64,
             positions: *[ID_CAPACITY]i32, start: usize) void {
    var index = start;
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (priorities[index] <= priorities[parent]) break;
        swapItems(ids, priorities, positions, index, parent);
        index = parent;
    }
}

fn heapifyDown(ids: *[MAX_ITEMS]i64, priorities: *[MAX_ITEMS]i64,
               positions: *[ID_CAPACITY]i32, heap_size: usize, start: usize) void {
    var index = start;
    while (true) {
        var best = index;
        const left = 2 * index + 1;
        const right = left + 1;
        if (left < heap_size and priorities[left] > priorities[best]) best = left;
        if (right < heap_size and priorities[right] > priorities[best]) best = right;
        if (best == index) return;
        swapItems(ids, priorities, positions, index, best);
        index = best;
    }
}

fn eraseItem(ids: *[MAX_ITEMS]i64, priorities: *[MAX_ITEMS]i64,
             positions: *[ID_CAPACITY]i32, heap_size: *usize, item_id: usize) void {
    const index: usize = @intCast(positions[item_id]);
    const last = heap_size.* - 1;
    positions[item_id] = -1;
    if (index != last) {
        ids[index] = ids[last];
        priorities[index] = priorities[last];
        positions[@intCast(ids[index])] = @intCast(index);
    }
    heap_size.* = last;
    if (index < heap_size.*) {
        heapifyUp(ids, priorities, positions, index);
        heapifyDown(ids, priorities, positions, heap_size.*, index);
    }
}

export fn heap_generic(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const operation_count_value = values[0];
    if (operation_count_value < 0 or operation_count_value > @as(i64, @intCast(MAX_OPERATIONS)) or
        length != 1 + 3 * @as(usize, @intCast(operation_count_value))) return -1;

    var ids: [MAX_ITEMS]i64 = @splat(0);
    var priorities: [MAX_ITEMS]i64 = @splat(0);
    var positions: [ID_CAPACITY]i32 = @splat(-1);
    var used_ids: [ID_CAPACITY]bool = @splat(false);
    var heap_size: usize = 0;
    var hash = FNV_OFFSET;

    for (0..@intCast(operation_count_value)) |operation| {
        const opcode = values[1 + 3 * operation];
        const item_id = values[2 + 3 * operation];
        const priority = values[3 + 3 * operation];
        var present = false;
        var returned_id: i64 = 0;
        var returned_priority: i64 = 0;

        if (opcode == 0) {
            if (item_id < 0 or item_id >= @as(i64, @intCast(ID_CAPACITY)) or priority < -2147483648 or priority > 2147483647 or
                used_ids[@intCast(item_id)] or heap_size >= MAX_ITEMS) return -1;
            for (0..heap_size) |i| if (priorities[i] == priority) return -1;
            used_ids[@intCast(item_id)] = true;
            ids[heap_size] = item_id;
            priorities[heap_size] = priority;
            positions[@intCast(item_id)] = @intCast(heap_size);
            heap_size += 1;
            heapifyUp(&ids, &priorities, &positions, heap_size - 1);
        } else if (opcode == 1 or opcode == 2) {
            if (item_id != 0 or priority != 0) return -1;
            if (heap_size > 0) {
                present = true;
                returned_id = ids[0];
                returned_priority = priorities[0];
                if (opcode == 2) eraseItem(&ids, &priorities, &positions, &heap_size, @intCast(ids[0]));
            }
        } else if (opcode == 3) {
            if (item_id < 0 or item_id >= @as(i64, @intCast(ID_CAPACITY)) or priority < -2147483648 or priority > 2147483647 or
                positions[@intCast(item_id)] < 0) return -1;
            const index: usize = @intCast(positions[@intCast(item_id)]);
            for (0..heap_size) |i| if (i != index and priorities[i] == priority) return -1;
            priorities[index] = priority;
            heapifyUp(&ids, &priorities, &positions, index);
            heapifyDown(&ids, &priorities, &positions, heap_size, index);
        } else if (opcode == 4) {
            if (item_id < 0 or item_id >= @as(i64, @intCast(ID_CAPACITY)) or priority != 0 or positions[@intCast(item_id)] < 0) return -1;
            eraseItem(&ids, &priorities, &positions, &heap_size, @intCast(item_id));
        } else return -1;

        hash = hashByte(hash, @intCast(opcode));
        hash = hashByte(hash, @intFromBool(present));
        if (present) {
            hash = hashI32(hash, returned_id);
            hash = hashI32(hash, returned_priority);
        }
    }
    return @bitCast(hash);
}
