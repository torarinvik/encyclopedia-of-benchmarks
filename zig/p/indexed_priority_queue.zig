const MAX_EVENTS: usize = 256;
const MAX_ACTIVE: usize = 64;
const MAX_INPUT_VALUES: usize = 1538;
const MAX_EVENTS_I64: i64 = @intCast(MAX_EVENTS);
const MAX_ACTIVE_I64: i64 = @intCast(MAX_ACTIVE);

fn storeI64Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn keyInUse(heapIds: []const i64, heapKeys: []const i64, size: usize, key: i64, exceptId: i64) bool {
    for (0..size) |index| if (heapIds[index] != exceptId and heapKeys[index] == key) return true;
    return false;
}

fn siftUp(heapIds: []i64, heapKeys: []i64, positions: []i32, indexValue: usize) bool {
    var index = indexValue;
    const original = index;
    const itemId = heapIds[index];
    const itemKey = heapKeys[index];
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (itemKey >= heapKeys[parent]) break;
        heapIds[index] = heapIds[parent];
        heapKeys[index] = heapKeys[parent];
        positions[@intCast(heapIds[index])] = @intCast(index);
        index = parent;
    }
    heapIds[index] = itemId;
    heapKeys[index] = itemKey;
    positions[@intCast(itemId)] = @intCast(index);
    return index != original;
}

fn siftDown(heapIds: []i64, heapKeys: []i64, positions: []i32, size: usize, indexValue: usize) void {
    var index = indexValue;
    const itemId = heapIds[index];
    const itemKey = heapKeys[index];
    const half = size / 2;
    while (index < half) {
        var child = index * 2 + 1;
        const right = child + 1;
        if (right < size and heapKeys[child] > heapKeys[right]) child = right;
        if (itemKey <= heapKeys[child]) break;
        heapIds[index] = heapIds[child];
        heapKeys[index] = heapKeys[child];
        positions[@intCast(heapIds[index])] = @intCast(index);
        index = child;
    }
    heapIds[index] = itemId;
    heapKeys[index] = itemKey;
    positions[@intCast(itemId)] = @intCast(index);
}

fn removeAt(size: *usize, heapIds: []i64, heapKeys: []i64, positions: []i32, index: usize) void {
    const newSize = size.* - 1;
    const removedId = heapIds[index];
    const movedId = heapIds[newSize];
    const movedKey = heapKeys[newSize];
    size.* = newSize;
    positions[@intCast(removedId)] = -1;
    if (index == newSize) return;
    heapIds[index] = movedId;
    heapKeys[index] = movedKey;
    positions[@intCast(movedId)] = @intCast(index);
    if (!siftUp(heapIds, heapKeys, positions, index))
        siftDown(heapIds, heapKeys, positions, size.*, index);
}

export fn indexed_priority_queue(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 or values[0] > MAX_EVENTS_I64) return -1;
    const eventCount: usize = @intCast(values[0]);
    if (length != 1 + 6 * eventCount) return -1;
    if (eventCount == 0) return 0;

    var heapIds: [MAX_ACTIVE]i64 = @splat(0);
    var heapKeys: [MAX_ACTIVE]i64 = @splat(0);
    var positions: [MAX_ACTIVE]i32 = @splat(-1);
    var records: [MAX_EVENTS][6]i64 = @splat(@splat(0));
    var size: usize = 0;

    for (0..eventCount) |eventIndex| {
        const start = 1 + eventIndex * 6;
        const opcode = values[start];
        const elementId = values[start + 1];
        const key = values[start + 2];
        if (values[start + 3] != 0 or values[start + 4] != 0 or values[start + 5] != 0) return -1;
        var status: i64 = 1;
        var resultId: i64 = 0;
        var resultKey: i64 = 0;

        if (opcode == 0) {
            if (elementId < 0 or elementId >= MAX_ACTIVE_I64 or key < -2147483648 or key > 2147483647) return -1;
            const id: usize = @intCast(elementId);
            if (positions[id] >= 0 or size >= MAX_ACTIVE or keyInUse(heapIds[0..], heapKeys[0..], size, key, -1)) return -1;
            heapIds[size] = elementId;
            heapKeys[size] = key;
            positions[id] = @intCast(size);
            size += 1;
            _ = siftUp(heapIds[0..], heapKeys[0..], positions[0..], size - 1);
        } else if (opcode == 1 or opcode == 2) {
            if (elementId != 0 or key != 0) return -1;
            if (size == 0) status = 0 else {
                resultId = heapIds[0];
                resultKey = heapKeys[0];
                if (opcode == 2) removeAt(&size, heapIds[0..], heapKeys[0..], positions[0..], 0);
            }
        } else if (opcode == 3 or opcode == 4) {
            if (elementId < 0 or elementId >= MAX_ACTIVE_I64 or key != 0) return -1;
            const id: usize = @intCast(elementId);
            const position = positions[id];
            status = if (position >= 0) 1 else 0;
            if (opcode == 3 and position >= 0)
                removeAt(&size, heapIds[0..], heapKeys[0..], positions[0..], @intCast(position));
        } else if (opcode >= 5 and opcode <= 7) {
            if (elementId < 0 or elementId >= MAX_ACTIVE_I64 or key < -2147483648 or key > 2147483647) return -1;
            const id: usize = @intCast(elementId);
            const position_value = positions[id];
            if (position_value < 0) return -1;
            const position: usize = @intCast(position_value);
            const oldKey = heapKeys[position];
            if ((opcode == 6 and key >= oldKey) or (opcode == 7 and key <= oldKey)
                or keyInUse(heapIds[0..], heapKeys[0..], size, key, elementId)) return -1;
            heapKeys[position] = key;
            if (opcode == 6) {
                _ = siftUp(heapIds[0..], heapKeys[0..], positions[0..], position);
            } else if (opcode == 7) {
                siftDown(heapIds[0..], heapKeys[0..], positions[0..], size, position);
            } else if (!siftUp(heapIds[0..], heapKeys[0..], positions[0..], position)) {
                siftDown(heapIds[0..], heapKeys[0..], positions[0..], size, position);
            }
        } else if (opcode == 8 or opcode == 9 or opcode == 10) {
            if (elementId != 0 or key != 0) return -1;
            if (opcode == 8) {
                for (0..size) |index| positions[@intCast(heapIds[index])] = -1;
                size = 0;
            } else if (opcode == 9) resultId = @intCast(size) else resultId = if (size == 0) 1 else 0;
        } else return -1;

        const minimumId: i64 = if (size == 0) 0 else heapIds[0];
        const minimumKey: i64 = if (size == 0) 0 else heapKeys[0];
        records[eventIndex] = .{ status, resultId, resultKey, @intCast(size), minimumId, minimumKey };
    }

    const required = eventCount * 48;
    if (output == null or output_capacity < required) return -2;
    for (0..eventCount) |eventIndex| {
        for (0..6) |field| storeI64Le(output, eventIndex * 48 + field * 8, records[eventIndex][field]);
    }
    return @intCast(required);
}
