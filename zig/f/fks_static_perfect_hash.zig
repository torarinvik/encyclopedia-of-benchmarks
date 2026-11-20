/// Deterministic bounded two-level FKS static perfect hashing.
fn hashIndex(a: usize, b: usize, modulus: usize, key: i64) usize {
    return ((a * @as(usize, @intCast(key)) + b) % 257) % modulus;
}

export fn fks_static_perfect_hash(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 19) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 8 or input[1] < 0 or input[1] > 8) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + n + q) return -1;
    for (0..n + q) |i| if (input[2 + i] < 0 or input[2 + i] > 255) { return -1; };
    for (0..n) |i| {
        for (i + 1..n) |j| if (input[2 + i] == input[2 + j]) { return -1; };
    }

    var bucket_of: [8]usize = @splat(0);
    var bucket_sizes: [8]usize = @splat(0);
    var first_a: usize = 0;
    var first_b: usize = 0;
    var first_found = n == 0;
    for (1..257) |a| {
        if (first_found) break;
        for (0..257) |b| {
            if (first_found) break;
            var counts: [8]usize = @splat(0);
            for (0..n) |i| counts[hashIndex(a, b, n, input[2 + i])] += 1;
            var square_sum: usize = 0;
            for (0..n) |bucket| square_sum += counts[bucket] * counts[bucket];
            if (square_sum <= 4 * n) {
                first_a = a;
                first_b = b;
                first_found = true;
            }
        }
    }
    if (!first_found) return -1;
    for (0..n) |i| {
        bucket_of[i] = hashIndex(first_a, first_b, n, input[2 + i]);
        bucket_sizes[bucket_of[i]] += 1;
    }

    var slot_keys: [8][64]i64 = @splat(@splat(0));
    var occupied: [8][64]bool = @splat(@splat(false));
    var local_a: [8]usize = @splat(0);
    var local_b: [8]usize = @splat(0);
    for (0..n) |bucket| {
        const count = bucket_sizes[bucket];
        if (count == 0) continue;
        const capacity = count * count;
        var local_found = false;
        for (1..257) |a| {
            if (local_found) break;
            for (0..257) |b| {
                if (local_found) break;
                var used: [64]bool = @splat(false);
                var collision = false;
                for (0..n) |i| {
                    if (bucket_of[i] == bucket) {
                        const position = hashIndex(a, b, capacity, input[2 + i]);
                        if (used[position]) { collision = true; break; }
                        used[position] = true;
                    }
                }
                if (!collision) {
                    local_a[bucket] = a;
                    local_b[bucket] = b;
                    for (0..n) |i| {
                        if (bucket_of[i] == bucket) {
                            const position = hashIndex(a, b, capacity, input[2 + i]);
                            slot_keys[bucket][position] = input[2 + i];
                            occupied[bucket][position] = true;
                        }
                    }
                    local_found = true;
                }
            }
        }
        if (!local_found) return -1;
    }

    var result: i64 = 0;
    for (0..q) |i| {
        const query = input[2 + n + i];
        var present = false;
        if (n > 0) {
            const bucket = hashIndex(first_a, first_b, n, query);
            const count = bucket_sizes[bucket];
            if (count > 0) {
                const position = hashIndex(local_a[bucket], local_b[bucket], count * count, query);
                present = occupied[bucket][position] and slot_keys[bucket][position] == query;
            }
        }
        if (present) result |= @as(i64, 1) << @intCast(i);
    }
    return result;
}
