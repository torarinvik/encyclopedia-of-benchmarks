export fn key_priority_queue(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 98) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 32) return -1;
    var keys: [32]i64 = undefined;
    var priorities: [32]i64 = undefined;
    var answers: [32]i64 = undefined;
    var n: usize = 0;
    var out_n: usize = 0;
    var pos: usize = 1;
    for (0..@intCast(input[0])) |_| {
        if (pos >= length) return -1;
        const op = input[pos];
        if (op == 0 or op == 1) {
            if (pos + 2 >= length) return -1;
            const key = input[pos + 1];
            const priority = input[pos + 2];
            if (key < -1000000000 or key > 1000000000 or priority < -1000000000 or priority > 1000000000) return -1;
            pos += 3;
            var found = n;
            for (0..n) |i| { if (keys[i] == key) { found = i; break; } }
            if (op == 0 and found != n) return -1;
            if (found == n) {
                keys[n] = key;
                priorities[n] = priority;
                var i = n;
                while (i > 0) {
                    const parent = (i - 1) / 2;
                    if (priorities[parent] <= priorities[i]) break;
                    swap(&keys[parent], &keys[i]);
                    swap(&priorities[parent], &priorities[i]);
                    i = parent;
                }
                n += 1;
            } else {
                priorities[found] = priority;
                if (found > 0 and priorities[(found - 1) / 2] > priority) {
                    var i = found;
                    while (i > 0) {
                        const parent = (i - 1) / 2;
                        if (priorities[parent] <= priorities[i]) break;
                        swap(&keys[parent], &keys[i]);
                        swap(&priorities[parent], &priorities[i]);
                        i = parent;
                    }
                } else {
                    const left = 2 * found + 1;
                    const right = left + 1;
                    if ((left < n and priorities[left] < priority) or (right < n and priorities[right] < priority)) {
                        var i = found;
                        while (2 * i + 1 < n) {
                            const l = 2 * i + 1;
                            const r = l + 1;
                            var child = n;
                            if (priorities[l] < priorities[i] and (r >= n or priorities[l] < priorities[r])) child = l
                            else if (r < n and priorities[r] < priorities[i]) child = r
                            else break;
                            swap(&keys[i], &keys[child]);
                            swap(&priorities[i], &priorities[child]);
                            i = child;
                        }
                    }
                }
            }
        } else if (op == 2) {
            pos += 1;
            if (n == 0) return -1;
            swap(&keys[0], &keys[n - 1]);
            swap(&priorities[0], &priorities[n - 1]);
            n -= 1;
            answers[out_n] = keys[n];
            out_n += 1;
            if (n > 0) {
                var i: usize = 0;
                while (2 * i + 1 < n) {
                    const l = 2 * i + 1;
                    const r = l + 1;
                    var child = n;
                    if (priorities[l] < priorities[i] and (r >= n or priorities[l] < priorities[r])) child = l
                    else if (r < n and priorities[r] < priorities[i]) child = r
                    else break;
                    swap(&keys[i], &keys[child]);
                    swap(&priorities[i], &priorities[child]);
                    i = child;
                }
            }
        } else if (op == 3) {
            if (pos + 1 >= length) return -1;
            const key = input[pos + 1];
            if (key < -1000000000 or key > 1000000000) return -1;
            pos += 2;
            var present = false;
            for (0..n) |i| { if (keys[i] == key) { present = true; break; } }
            answers[out_n] = if (present) 1 else 0;
            out_n += 1;
        } else if (op == 4) {
            pos += 1;
            answers[out_n] = if (n == 0) 1 else 0;
            out_n += 1;
        } else return -1;
    }
    if (pos != length) return -1;
    const bytes = out_n * 8;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..out_n) |i| {
        const bits: u64 = @bitCast(answers[i]);
        for (0..8) |b| output[8 * i + b] = @truncate(bits >> @intCast(8 * b));
    }
    return @intCast(bytes);
}

fn swap(a: *i64, b: *i64) void {
    const value = a.*;
    a.* = b.*;
    b.* = value;
}
