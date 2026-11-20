module fenwick_kth;

fn long fenwick_kth(long* input, usz length) @export("fenwick_kth") {
    if (input == null || length < 3 || length > 163) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    usz n = (usz)input[0];
    usz q = (usz)input[1];
    if (length != 2 + n + 3 * q) return -1;

    long[64] frequency = zeroed;
    long[65] tree = zeroed;
    long total = 0;
    for (usz i = 0; i < n; i++) {
        long value = input[2 + i];
        if (value < 0 || value > 1000000) return -1;
        frequency[i] = value;
        total += value;
        usz index = i + 1;
        tree[index] += value;
        usz parent = index + (index & (0 - index));
        if (parent <= n) tree[parent] += tree[index];
    }

    long result = 0;
    usz query_number = 0;
    usz cursor = 2 + n;
    for (usz operation = 0; operation < q; operation++) {
        long opcode = input[cursor];
        long first = input[cursor + 1];
        long second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= (long)n || second < -1000000 || second > 1000000) return -1;
            usz position = (usz)first;
            long updated = frequency[position] + second;
            if (updated < 0 || updated > 1000000) return -1;
            frequency[position] = updated;
            total += second;
            usz index = position + 1;
            while (index <= n) {
                tree[index] += second;
                index += index & (0 - index);
            }
        } else if (opcode == 1) {
            if (second != 0) return -1;
            long answer = -1;
            if (first > 0 && first <= total) {
                usz index = 0;
                usz step = 1;
                while (step <= n / 2) step *= 2;
                long rank = first;
                while (step != 0) {
                    usz candidate = index + step;
                    if (candidate <= n && tree[candidate] < rank) {
                        index = candidate;
                        rank -= tree[candidate];
                    }
                    step /= 2;
                }
                answer = (long)index;
            }
            result += (long)(query_number + 1) * (answer + 1);
            query_number++;
        } else return -1;
    }
    return result;
}
