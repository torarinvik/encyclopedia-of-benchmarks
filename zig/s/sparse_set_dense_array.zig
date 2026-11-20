const max_universe: usize = 32;
const max_operations: usize = 30;
const max_length: usize = 63;

export fn sparse_set_dense_array(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64,@intCast(max_universe))
            or words[1] < 0 or words[1] > @as(i64,@intCast(max_operations))) return -1;
    const universe: usize = @intCast(words[0]);
    const count: usize = @intCast(words[1]);
    if (length != 2+2*count) return -1;
    for (0..count) |i| {
        const opcode = words[2+2*i];
        const key = words[3+2*i];
        if (opcode < 0 or opcode > 3 or key < 0 or key >= @as(i64,@intCast(universe))) return -1;
        if (opcode == 3 and key != 0) return -1;
    }

    var dense = [_]usize{0} ** max_universe;
    var sparse = [_]usize{universe} ** max_universe;
    var size: usize = 0;
    var answers: i64 = 0;
    for (0..count) |i| {
        const opcode: usize = @intCast(words[2+2*i]);
        const key: usize = @intCast(words[3+2*i]);
        const index = sparse[key];
        const present = index < size and dense[index] == key;
        var status: i64 = 0;
        if (opcode == 0) {
            if (!present) {
                dense[size] = key;
                sparse[key] = size;
                size += 1;
                status = 1;
            }
        } else if (opcode == 1) {
            if (present) {
                const last = dense[size-1];
                dense[index] = last;
                sparse[last] = index;
                size -= 1;
                status = 1;
            }
        } else if (opcode == 2) {
            status = @intFromBool(present);
        } else {
            status = @intFromBool(size != 0);
            size = 0;
        }
        answers = (answers << 1) | status;
    }
    var final_mask: i64 = 0;
    for (dense[0..size]) |key| final_mask |= @as(i64,1) << @intCast(key);
    return (final_mask << @intCast(count)) | answers;
}
