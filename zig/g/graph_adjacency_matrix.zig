const MAX_VERTICES: usize = 8;
const MAX_EDGES: i64 = 64;
const MAX_OPERATION_COUNT: i64 = 24;
const MAX_OPERATIONS: usize = 24;

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

fn vertexIndex(vertices: *const [MAX_VERTICES]i64, count: usize, value: i64) ?usize {
    for (0..count) |index| if (vertices[index] == value) return index;
    return null;
}

fn removeVertex(vertices: *[MAX_VERTICES]i64, matrix: *[MAX_VERTICES * MAX_VERTICES]i64, count: *usize, index: usize) void {
    const old_count = count.*;
    for (index..old_count - 1) |row| {
        vertices[row] = vertices[row + 1];
        for (0..old_count) |column| matrix[row * MAX_VERTICES + column] = matrix[(row + 1) * MAX_VERTICES + column];
    }
    for (0..old_count - 1) |row| {
        for (index..old_count - 1) |column| matrix[row * MAX_VERTICES + column] = matrix[row * MAX_VERTICES + column + 1];
    }
    for (0..old_count) |i| {
        matrix[(old_count - 1) * MAX_VERTICES + i] = 0;
        matrix[i * MAX_VERTICES + old_count - 1] = 0;
    }
    count.* = old_count - 1;
}

export fn graph_adjacency_matrix(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const directed = input[0];
    const count_value = input[1];
    if ((directed != 0 and directed != 1) or count_value < 0 or count_value > 8) return -1;
    var count: usize = @intCast(count_value);
    if (length < 3 + count) return -1;

    var vertices: [MAX_VERTICES]i64 = @splat(0);
    var matrix: [MAX_VERTICES * MAX_VERTICES]i64 = @splat(0);
    var position: usize = 2;
    for (0..count) |index| {
        const value = input[position];
        position += 1;
        if (value < 0 or value >= 32 or vertexIndex(&vertices, index, value) != null) return -1;
        vertices[index] = value;
    }
    if (position >= length) return -1;
    const edge_count = input[position];
    position += 1;
    if (edge_count < 0 or edge_count > MAX_EDGES or length < position + 2 * @as(usize, @intCast(edge_count)) + 1) return -1;
    for (0..@as(usize, @intCast(edge_count))) |_| {
        const source_value = input[position];
        const destination_value = input[position + 1];
        position += 2;
        if (source_value < 0 or source_value >= 32 or destination_value < 0 or destination_value >= 32) return -1;
        const source = vertexIndex(&vertices, count, source_value) orelse return -1;
        const destination = vertexIndex(&vertices, count, destination_value) orelse return -1;
        if (matrix[source * MAX_VERTICES + destination] != 0) return -1;
        matrix[source * MAX_VERTICES + destination] = 1;
        if (directed == 0) matrix[destination * MAX_VERTICES + source] = 1;
    }
    const operation_count_value = input[position];
    position += 1;
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATION_COUNT or
        length != position + 3 * @as(usize, @intCast(operation_count_value))) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var results: [MAX_OPERATIONS]i64 = @splat(0);
    for (0..operation_count) |operation_index| {
        const operation = input[position];
        const a = input[position + 1];
        const b = input[position + 2];
        position += 3;
        if (operation == 0) {
            if (a < 0 or a >= 32 or b != 0 or count >= MAX_VERTICES or vertexIndex(&vertices, count, a) != null) return -1;
            for (0..MAX_VERTICES) |i| {
                matrix[i * MAX_VERTICES + count] = 0;
                matrix[count * MAX_VERTICES + i] = 0;
            }
            vertices[count] = a;
            count += 1;
            results[operation_index] = 1;
        } else if (operation == 1) {
            if (a < 0 or a >= 32 or b != 0) return -1;
            const removed = vertexIndex(&vertices, count, a) orelse return -1;
            removeVertex(&vertices, &matrix, &count, removed);
            results[operation_index] = 1;
        } else if (operation == 2 or operation == 3 or operation == 5) {
            if (a < 0 or a >= 32 or b < 0 or b >= 32) return -1;
            const source = vertexIndex(&vertices, count, a) orelse return -1;
            const destination = vertexIndex(&vertices, count, b) orelse return -1;
            const cell = source * MAX_VERTICES + destination;
            const present = matrix[cell] != 0;
            if (operation == 5) {
                results[operation_index] = if (present) 1 else 0;
            } else if (operation == 2) {
                if (present) return -1;
                matrix[cell] = 1;
                if (directed == 0) matrix[destination * MAX_VERTICES + source] = 1;
                results[operation_index] = 1;
            } else {
                if (!present) return -1;
                matrix[cell] = 0;
                if (directed == 0) matrix[destination * MAX_VERTICES + source] = 0;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (a < 0 or a >= 32 or b != 0) return -1;
            results[operation_index] = if (vertexIndex(&vertices, count, a) != null) 1 else 0;
        } else if (operation == 6) {
            if (a != 0 or b != 0) return -1;
            count = 0;
            matrix = @splat(0);
            results[operation_index] = 1;
        } else return -1;
    }

    const words = 2 + operation_count + count + count * count;
    if (output == null or capacity < words * 8) return -2;
    var word: usize = 0;
    putI64Le(output, word, @intCast(operation_count)); word += 1;
    for (0..operation_count) |index| { putI64Le(output, word, results[index]); word += 1; }
    putI64Le(output, word, @intCast(count)); word += 1;
    for (0..count) |index| { putI64Le(output, word, vertices[index]); word += 1; }
    for (0..count) |row| {
        for (0..count) |column| {
            putI64Le(output, word, matrix[row * MAX_VERTICES + column]);
            word += 1;
        }
    }
    return @intCast(words * 8);
}
