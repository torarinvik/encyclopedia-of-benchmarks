const MAX_CAPACITY: usize = 32;
const MAX_INPUT_LENGTH: usize = 35;
const MAX_KEY: i64 = 1_000_000;

export fn lcfs_hashing(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const capacity_value = values[0];
    const count_value = values[1];
    if (capacity_value < 1 or capacity_value > MAX_CAPACITY or count_value < 0
        or count_value > capacity_value or length != @as(usize, @intCast(count_value)) + 2) return -1;
    const capacity: usize = @intCast(capacity_value);
    const count: usize = @intCast(count_value);
    for (0..count) |i| {
        const key = values[i + 2];
        if (key < 0 or key > MAX_KEY) return -1;
        for (0..i) |j| if (values[j + 2] == key) return -1;
    }

    var table: [MAX_CAPACITY]i64 = @splat(-1);
    var displacements: i64 = 0;
    for (0..count) |i| {
        var incoming = values[i + 2];
        var slot: usize = @intCast(@mod(incoming, capacity_value));
        var probes: usize = 0;
        while (table[slot] != -1) {
            if (probes >= capacity) return -1;
            const resident = table[slot];
            table[slot] = incoming;
            incoming = resident;
            slot = (slot + 1) % capacity;
            probes += 1;
            displacements += 1;
        }
        table[slot] = incoming;
    }
    return displacements;
}
