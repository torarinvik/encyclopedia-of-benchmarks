const MAX_WORDS: usize = 16;
const MAX_QUERIES: usize = 8;
const MAX_WORD_LENGTH: usize = 10;

fn validWord(word: i64) bool {
    if (word < 0) return false;
    const packed: u64 = @intCast(word);
    if ((packed >> 44) != 0) return false;
    const word_length: usize = @intCast((packed >> 40) & 15);
    if (word_length > MAX_WORD_LENGTH) return false;
    for (0..MAX_WORD_LENGTH) |position| {
        const symbol = (packed >> @intCast(4 * position)) & 15;
        if (position < word_length) {
            if (symbol == 0) return false;
        } else if (symbol != 0) return false;
    }
    return true;
}

fn editDistance(left: i64, right: i64) usize {
    const a: u64 = @intCast(left);
    const b: u64 = @intCast(right);
    const n: usize = @intCast((a >> 40) & 15);
    const m: usize = @intCast((b >> 40) & 15);
    var previous: [MAX_WORD_LENGTH + 1]usize = undefined;
    var current: [MAX_WORD_LENGTH + 1]usize = undefined;
    for (0..m + 1) |j| previous[j] = j;
    for (1..n + 1) |i| {
        current[0] = i;
        const a_symbol = (a >> @intCast(4 * (i - 1))) & 15;
        for (1..m + 1) |j| {
            const b_symbol = (b >> @intCast(4 * (j - 1))) & 15;
            const deletion = previous[j] + 1;
            const insertion = current[j - 1] + 1;
            const replacement = previous[j - 1] + @as(usize, if (a_symbol == b_symbol) 0 else 1);
            current[j] = @min(deletion, @min(insertion, replacement));
        }
        previous = current;
    }
    return previous[m];
}

export fn bk_tree_edit_distance_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 28) return -1;
    const values = input.?;
    const n_value = values[0];
    const q_value = values[1];
    const radius_value = values[2];
    if (n_value < 0 or n_value > MAX_WORDS or q_value < 0 or q_value > MAX_QUERIES
        or radius_value < 0 or radius_value > 3
        or length != @as(usize, @intCast(3 + n_value + q_value))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    const radius: usize = @intCast(radius_value);
    for (0..n + q) |i| if (!validWord(values[i + 3])) return -1;
    for (0..n) |i| {
        for (0..i) |j| {
            if (values[i + 3] == values[j + 3]) return -1;
        }
    }

    var children: [MAX_WORDS][MAX_WORD_LENGTH + 1]i32 = undefined;
    for (0..MAX_WORDS) |i| {
        for (0..MAX_WORD_LENGTH + 1) |edge| {
            children[i][edge] = -1;
        }
    }
    var node: usize = 1;
    while (node < n) : (node += 1) {
        var pivot: usize = 0;
        while (true) {
            const edge = editDistance(values[node + 3], values[pivot + 3]);
            if (children[pivot][edge] == -1) {
                children[pivot][edge] = @intCast(node);
                break;
            }
            pivot = @intCast(children[pivot][edge]);
        }
    }

    var result: i64 = 0;
    for (0..q) |query_index| {
        var matches: i64 = 0;
        var index_sum: i64 = 0;
        if (n != 0) {
            var stack: [MAX_WORDS]usize = undefined;
            var top: usize = 1;
            stack[0] = 0;
            while (top != 0) {
                top -= 1;
                const node = stack[top];
                const distance = editDistance(values[3 + n + query_index], values[node + 3]);
                if (distance <= radius) {
                    matches += 1;
                    index_sum += @intCast(node);
                }
                const low = if (distance > radius) distance - radius else 0;
                const high = @min(distance + radius, MAX_WORD_LENGTH);
                for (low..high + 1) |edge| {
                    const child = children[node][edge];
                    if (child >= 0) {
                        stack[top] = @intCast(child);
                        top += 1;
                    }
                }
            }
        }
        result += (@as(i64, @intCast(query_index)) + 1) * (17 * matches + index_sum);
    }
    return result;
}
