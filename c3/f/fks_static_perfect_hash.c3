module fks_static_perfect_hash;

fn usz hash_index(usz a, usz b, usz modulus, long key) {
    return (((a * (usz)key + b) % 257) % modulus);
}

fn long fks_static_perfect_hash(long* input, usz length) @export("fks_static_perfect_hash") {
    if (input == null || length < 2 || length > 19) return -1;
    if (input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8) return -1;
    usz n = (usz)input[0];
    usz q = (usz)input[1];
    if (length != 2 + n + q) return -1;
    for (usz i = 0; i < n + q; i++) if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    for (usz i = 0; i < n; i++) for (usz j = i + 1; j < n; j++)
        if (input[2 + i] == input[2 + j]) return -1;

    usz[8] bucket_of = zeroed;
    usz[8] bucket_sizes = zeroed;
    usz first_a = 0, first_b = 0;
    bool first_found = n == 0;
    for (usz a = 1; a <= 256 && !first_found; a++) {
        for (usz b = 0; b <= 256 && !first_found; b++) {
            usz[8] counts = zeroed;
            for (usz i = 0; i < n; i++) counts[hash_index(a, b, n, input[2 + i])]++;
            usz square_sum = 0;
            for (usz k = 0; k < n; k++) square_sum += counts[k] * counts[k];
            if (square_sum <= 4 * n) { first_a = a; first_b = b; first_found = true; }
        }
    }
    if (!first_found) return -1;
    for (usz i = 0; i < n; i++) {
        bucket_of[i] = hash_index(first_a, first_b, n, input[2 + i]);
        bucket_sizes[bucket_of[i]]++;
    }

    long[8][64] slot_keys = zeroed;
    bool[8][64] occupied = zeroed;
    usz[8] local_a = zeroed, local_b = zeroed;
    for (usz bucket = 0; bucket < n; bucket++) {
        usz count = bucket_sizes[bucket];
        if (count == 0) continue;
        usz capacity = count * count;
        bool local_found = false;
        for (usz a = 1; a <= 256 && !local_found; a++) {
            for (usz b = 0; b <= 256 && !local_found; b++) {
                bool[64] used = zeroed;
                bool collision = false;
                for (usz i = 0; i < n; i++) if (bucket_of[i] == bucket) {
                    usz position = hash_index(a, b, capacity, input[2 + i]);
                    if (used[position]) { collision = true; break; }
                    used[position] = true;
                }
                if (!collision) {
                    local_a[bucket] = a;
                    local_b[bucket] = b;
                    for (usz i = 0; i < n; i++) if (bucket_of[i] == bucket) {
                        usz position = hash_index(a, b, capacity, input[2 + i]);
                        slot_keys[bucket][position] = input[2 + i];
                        occupied[bucket][position] = true;
                    }
                    local_found = true;
                }
            }
        }
        if (!local_found) return -1;
    }

    long result = 0;
    for (usz i = 0; i < q; i++) {
        bool present = false;
        if (n > 0) {
            long query = input[2 + n + i];
            usz bucket = hash_index(first_a, first_b, n, query);
            usz count = bucket_sizes[bucket];
            usz capacity = count * count;
            if (capacity > 0) {
                usz position = hash_index(local_a[bucket], local_b[bucket], capacity, query);
                present = occupied[bucket][position] && slot_keys[bucket][position] == query;
            }
        }
        if (present) result |= (long)1 << i;
    }
    return result;
}
