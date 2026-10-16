const CURSOR_SPACE_SIZE = 100;
const MAX_OPERATIONS = 64;

fn findValue(elements: *[CURSOR_SPACE_SIZE]i64, occupied: *[CURSOR_SPACE_SIZE]bool,
    links: *[CURSOR_SPACE_SIZE]i64, head: i64, value: i64) struct { previous: i64, found: i64 } {
    var previous: i64 = -1;
    var found = head;
    while (found != -1 and (!occupied[@intCast(found)] or elements[@intCast(found)] != value)) {
        previous = found;
        found = links[@intCast(found)];
    }
    return .{ .previous = previous, .found = found };
}

fn freeNode(elements: *[CURSOR_SPACE_SIZE]i64, occupied: *[CURSOR_SPACE_SIZE]bool,
    links: *[CURSOR_SPACE_SIZE]i64, index: usize) void {
    const old_free_head = links[0];
    occupied[index] = false;
    elements[index] = 0;
    links[index] = old_free_head;
    links[0] = @intCast(index);
}

fn removeValue(elements: *[CURSOR_SPACE_SIZE]i64, occupied: *[CURSOR_SPACE_SIZE]bool,
    links: *[CURSOR_SPACE_SIZE]i64, head: *i64, count: *i64, value: i64) bool {
    if (head.* == -1) return false;
    const found = findValue(elements, occupied, links, head.*, value);
    if (found.found == -1) return false;
    const current: usize = @intCast(found.found);
    const successor = links[current];
    if (found.previous == -1) {
        freeNode(elements, occupied, links, current);
        head.* = successor;
    } else {
        links[@intCast(found.previous)] = successor;
        freeNode(elements, occupied, links, current);
    }
    count.* -= 1;
    return true;
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn cursor_linked_list(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values[0]);
    if (length != 1 + 2 * operation_count) return -1;
    var elements: [CURSOR_SPACE_SIZE]i64 = @splat(0);
    var links: [CURSOR_SPACE_SIZE]i64 = @splat(0);
    var occupied: [CURSOR_SPACE_SIZE]bool = @splat(false);
    for (0..CURSOR_SPACE_SIZE) |i| links[i] = @intCast(i + 1);
    links[CURSOR_SPACE_SIZE - 1] = 0;
    var head: i64 = -1;
    var count: i64 = 0;
    var query_found: [MAX_OPERATIONS]i64 = @splat(0);
    var query_values: [MAX_OPERATIONS]i64 = @splat(0);
    var query_count: usize = 0;

    for (0..operation_count) |index| {
        const operation = values[1 + 2 * index];
        const argument = values[2 + 2 * index];
        if (operation < 0 or operation > 4 or argument < -2147483648 or argument > 2147483647) return -1;
        if (operation == 0) {
            const available: usize = @intCast(links[0]);
            if (available == 0) return -1;
            links[0] = links[available];
            links[available] = -1;
            elements[available] = argument;
            occupied[available] = true;
            if (head == -1) head = @intCast(available) else {
                var tail: usize = @intCast(head);
                while (links[tail] != -1) tail = @intCast(links[tail]);
                links[tail] = @intCast(available);
            }
            links[available] = -1;
            count += 1;
        } else if (operation == 1) {
            if (!removeValue(&elements, &occupied, &links, &head, &count, argument)) return -1;
        } else if (operation == 2) {
            if (argument < 0 or argument >= count) return -1;
            var cursor: usize = @intCast(head);
            for (0..@intCast(argument)) |_| cursor = @intCast(links[cursor]);
            const value = elements[cursor];
            if (!removeValue(&elements, &occupied, &links, &head, &count, value)) return -1;
        } else if (operation == 3) {
            if (argument >= 0 and argument < count) {
                var cursor: usize = @intCast(head);
                for (0..@as(usize, @intCast(argument))) |_| cursor = @intCast(links[cursor]);
                query_found[query_count] = 1;
                query_values[query_count] = elements[cursor];
            }
            query_count += 1;
        } else {
            const found = findValue(&elements, &occupied, &links, head, argument);
            if (found.found != -1) {
                var logical_index: i64 = 0;
                var cursor = head;
                while (cursor != found.found) { cursor = links[@intCast(cursor)]; logical_index += 1; }
                query_found[query_count] = 1;
                query_values[query_count] = logical_index;
            }
            query_count += 1;
        }
    }

    const required = (1 + 2 * query_count + 2 + 3 * CURSOR_SPACE_SIZE) * 8;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    var field: usize = 0;
    putI64(out, field * 8, @intCast(query_count)); field += 1;
    for (0..query_count) |i| { putI64(out, field * 8, query_found[i]); field += 1; putI64(out, field * 8, query_values[i]); field += 1; }
    putI64(out, field * 8, head); field += 1;
    putI64(out, field * 8, count); field += 1;
    for (0..CURSOR_SPACE_SIZE) |i| {
        putI64(out, field * 8, if (occupied[i]) 1 else 0); field += 1;
        putI64(out, field * 8, elements[i]); field += 1;
        putI64(out, field * 8, links[i]); field += 1;
    }
    return @intCast(required);
}
