const MAX_NODES = 64;
const MAX_OPERATIONS = 64;
const MAX_RECORD_FIELDS = 5000;

fn rotateList(next: *[MAX_NODES]i64, previous: *[MAX_NODES]i64, head: *i64, size: i64, places: i64) void {
    if (size == 0) return;
    var steps = @rem(places, size);
    if (steps < 0) steps += size;
    if (steps > @divTrunc(size, 2)) {
        steps = size - steps;
        for (0..@intCast(steps)) |_| head.* = previous[@intCast(head.*)];
    } else {
        for (0..@intCast(steps)) |_| head.* = next[@intCast(head.*)];
    }
}

fn deleteHead(values: *[MAX_NODES]i64, next: *[MAX_NODES]i64, previous: *[MAX_NODES]i64,
    head: *i64, size: *i64) bool {
    if (size.* == 0) return false;
    const current: usize = @intCast(head.*);
    if (size.* == 1) head.* = -1 else {
        const successor = next[current];
        const predecessor = previous[current];
        next[@intCast(predecessor)] = successor;
        previous[@intCast(successor)] = predecessor;
        head.* = successor;
    }
    values[current] = 0;
    size.* -= 1;
    return true;
}

fn addRecord(records: *[MAX_RECORD_FIELDS]i64, field_count: *usize, value: i64) void {
    records[field_count.*] = value;
    field_count.* += 1;
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn cyclic(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values_in = input.?;
    if (values_in[0] < 0 or values_in[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values_in[0]);
    if (length != 1 + 2 * operation_count) return -1;
    var values: [MAX_NODES]i64 = @splat(0);
    var next: [MAX_NODES]i64 = @splat(0);
    var previous: [MAX_NODES]i64 = @splat(0);
    var head: i64 = -1;
    var size: i64 = 0;
    var allocated: usize = 0;
    var records: [MAX_RECORD_FIELDS]i64 = @splat(0);
    var record_fields: usize = 0;
    var query_count: usize = 0;

    for (0..operation_count) |index| {
        const operation = values_in[1 + 2 * index];
        const argument = values_in[2 + 2 * index];
        if (operation < 0 or operation > 5) return -1;
        if (operation == 0) {
            if (argument < -2147483648 or argument > 2147483647 or allocated >= MAX_NODES) return -1;
            const node = allocated;
            allocated += 1;
            values[node] = argument;
            if (size == 0) { head = @intCast(node); next[node] = head; previous[node] = head; }
            else {
                const tail: usize = @intCast(previous[@intCast(head)]);
                previous[node] = @intCast(tail); next[node] = head;
                next[tail] = @intCast(node); previous[@intCast(head)] = @intCast(node);
            }
            size += 1;
        } else if (operation == 1) {
            if (argument < -1000000 or argument > 1000000) return -1;
            rotateList(&next, &previous, &head, size, argument);
        } else if (operation == 2) {
            if (argument != 0) return -1;
            const deleted: i64 = if (deleteHead(&values, &next, &previous, &head, &size)) 1 else 0;
            addRecord(&records, &record_fields, @intCast(index)); addRecord(&records, &record_fields, operation);
            addRecord(&records, &record_fields, 1); addRecord(&records, &record_fields, deleted); query_count += 1;
        } else if (operation == 3) {
            if (argument != 0) return -1;
            addRecord(&records, &record_fields, @intCast(index)); addRecord(&records, &record_fields, operation); addRecord(&records, &record_fields, size);
            var cursor = head;
            for (0..@intCast(size)) |_| { addRecord(&records, &record_fields, values[@intCast(cursor)]); cursor = next[@intCast(cursor)]; }
            query_count += 1;
        } else if (operation == 4) {
            if (argument < -1000000 or argument > 1000000 or size == 0) return -1;
            while (size > 1) {
                rotateList(&next, &previous, &head, size, argument);
                _ = deleteHead(&values, &next, &previous, &head, &size);
                rotateList(&next, &previous, &head, size, -1);
            }
            const winner = values[@intCast(head)];
            while (deleteHead(&values, &next, &previous, &head, &size)) {}
            addRecord(&records, &record_fields, @intCast(index)); addRecord(&records, &record_fields, operation);
            addRecord(&records, &record_fields, 1); addRecord(&records, &record_fields, winner); query_count += 1;
        } else {
            if (argument != 0) return -1;
            while (deleteHead(&values, &next, &previous, &head, &size)) {}
        }
    }

    const required = (1 + record_fields + 1 + @as(usize, @intCast(size))) * 8;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    var field: usize = 0;
    putI64(out, field * 8, @intCast(query_count)); field += 1;
    for (0..record_fields) |i| { putI64(out, field * 8, records[i]); field += 1; }
    putI64(out, field * 8, size); field += 1;
    var cursor = head;
    for (0..@intCast(size)) |_| { putI64(out, field * 8, values[@intCast(cursor)]); field += 1; cursor = next[@intCast(cursor)]; }
    return @intCast(required);
}
