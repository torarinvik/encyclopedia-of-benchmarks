/// Bounded port of the pinned Java Library Sort gap-insertion routine.
const MAX_ITEMS: usize = 256;
const MAX_CAPACITY: usize = 2 * MAX_ITEMS;
const I32_MAX: i64 = 2_147_483_647;

fn findInsertionIndex(data: *const [MAX_CAPACITY]i64,
                     occupied: *const [MAX_CAPACITY]bool,
                     capacity: usize, value: i64) usize {
    var low: usize = 0;
    var high = capacity;
    while (low < high) {
        const middle = low + (high - low) / 2;
        var probe = I32_MAX;
        var index = middle;
        while (index < capacity) : (index += 1) {
            if (occupied[index]) { probe = data[index]; break; }
        }
        if (probe != I32_MAX and probe <= value) low = middle + 1 else high = middle;
    }
    return low;
}

fn insertAtEnd(data: *[MAX_CAPACITY]i64, occupied: *[MAX_CAPACITY]bool,
               capacity: usize, value: i64) void {
    const last = capacity - 1;
    var left: isize = @as(isize, @intCast(last)) - 1;
    while (left >= 0 and occupied[@intCast(left)]) : (left -= 1) {}
    if (left < 0) return;
    const gap: usize = @intCast(left);
    for (gap..last) |index| data[index] = data[index + 1];
    occupied[gap] = true;
    data[last] = value;
}

fn insertValue(data: *[MAX_CAPACITY]i64, occupied: *[MAX_CAPACITY]bool,
               capacity: usize, value: i64) void {
    const position = findInsertionIndex(data, occupied, capacity, value);
    if (position >= capacity) { insertAtEnd(data, occupied, capacity, value); return; }
    if (!occupied[position]) { data[position] = value; occupied[position] = true; return; }

    var right = position;
    while (right < capacity and occupied[right]) : (right += 1) {}
    var left: isize = @as(isize, @intCast(position)) - 1;
    while (left >= 0 and occupied[@intCast(left)]) : (left -= 1) {}
    const can_go_right = right < capacity;
    const can_go_left = left >= 0;
    if (can_go_right and (!can_go_left or right - position <= position - @as(usize, @intCast(left)))) {
        var index = right;
        while (index > position) : (index -= 1) data[index] = data[index - 1];
        occupied[right] = true;
        data[position] = value;
    } else if (can_go_left) {
        const gap: usize = @intCast(left);
        var index = gap;
        while (index + 1 < position) : (index += 1) data[index] = data[index + 1];
        occupied[gap] = true;
        data[position - 1] = value;
    }
}

export fn library_sort(values: [*c]i64, length: usize) void {
    if (values == null or length < 2 or length > MAX_ITEMS) return;
    const capacity = 2 * length;
    var data: [MAX_CAPACITY]i64 = @splat(0);
    var temporary: [MAX_ITEMS]i64 = @splat(0);
    var occupied: [MAX_CAPACITY]bool = @splat(false);
    var filled: usize = 1;
    var next: usize = 1;
    var round: usize = 0;
    const middle = capacity / 2;
    data[middle] = values[0];
    occupied[middle] = true;

    while (next < length) {
        const batch = @min(@as(usize, 1) << @intCast(round), length - next);
        for (0..batch) |index| {
            insertValue(&data, &occupied, capacity, values[next + index]);
            filled += 1;
        }
        next += batch;
        round += 1;
        if (next < length) {
            var at: usize = 0;
            for (0..capacity) |index| {
                if (occupied[index]) { temporary[at] = data[index]; at += 1; }
            }
            @memset(occupied[0..capacity], false);
            for (0..filled) |index| {
                const slot = index * capacity / filled;
                data[slot] = temporary[index];
                occupied[slot] = true;
            }
        }
    }

    var output: usize = 0;
    for (0..capacity) |index| {
        if (occupied[index]) { values[output] = data[index]; output += 1; }
    }
}
