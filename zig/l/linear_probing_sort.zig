const std = @import("std");

fn insertion_sort(values: [*]i64, length: usize) void {
    var index: usize = 1;
    while (index < length) : (index += 1) {
        const key = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > key) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[position] = key;
    }
}

export fn linear_probing_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    if (length > 1024) {
        insertion_sort(values, length);
        return;
    }

    var minimum = values[0];
    var maximum = values[0];
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 255) {
            insertion_sort(values, length);
            return;
        }
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }

    const main_slots = 256 * (length + 1) + 1;
    const table_length = main_slots + length;
    const allocator = std.heap.page_allocator;
    const table = allocator.alloc(i64, table_length) catch {
        insertion_sort(values, length);
        return;
    };
    defer allocator.free(table);
    @memset(table, 0);

    const span = maximum - minimum;
    for (0..length) |index| {
        const home: usize = if (span == 0) 0 else @intCast((values[index] - minimum) * @as(i64, @intCast(main_slots - 1)) / span);
        var slot = home;
        while (table[slot] != 0) : (slot += 1) {}
        table[slot] = values[index] + 1;
    }
    var output: usize = 0;
    for (table) |entry| {
        if (entry != 0) {
            values[output] = entry - 1;
            output += 1;
        }
    }
}
