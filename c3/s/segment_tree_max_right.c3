module segment_tree_max_right;

fn long segment_tree_max_right(long* input, usz length) @export("segment_tree_max_right") {
    if (input == null || length < 2 || length > 55) return -1;
    if (input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    usz n = (usz)input[0];
    usz operations = (usz)input[1];
    if (length != 2 + n + 3 * operations) return -1;
    long[64] tree = zeroed;
    usz size = 1;
    while (size < n) size *= 2;
    for (usz i = 0; i < n; i++) {
        long value = input[2 + i];
        if (value < 0 || value > 1000) return -1;
        tree[size + i] = value;
    }
    usz node = size;
    while (node > 1) {
        node--;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    usz query_index = 0;
    long result = 0;
    usz cursor = 2 + n;
    for (usz operation = 0; operation < operations; operation++) {
        long opcode = input[cursor];
        long first = input[cursor + 1];
        long second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= (long)n || second < 0 || second > 1000) return -1;
            node = size + (usz)first;
            tree[node] = second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[2 * node] + tree[2 * node + 1];
            }
        } else if (opcode == 1) {
            if (first < 0 || first > (long)n || second < 0 || second > 16000) return -1;
            usz left = (usz)first;
            usz boundary = n;
            if (left < n) {
                usz position = left + size;
                long accumulated = 0;
                bool done = false;
                while (!done) {
                    while ((position & 1) == 0) position /= 2;
                    if (accumulated + tree[position] > second) {
                        while (position < size) {
                            position *= 2;
                            if (accumulated + tree[position] <= second) {
                                accumulated += tree[position];
                                position++;
                            }
                        }
                        boundary = position - size;
                        if (boundary > n) boundary = n;
                        done = true;
                    } else {
                        accumulated += tree[position];
                        position++;
                        if ((position & (position - 1)) == 0) done = true;
                    }
                }
            }
            result |= (long)boundary << (5 * query_index);
            query_index++;
        } else return -1;
    }
    return result;
}
