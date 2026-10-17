module maximum_fenwick_tree;

fn long previous_bucket(long index) { return (index & (index + 1)) - 1; }

long maximum_fenwick_tree(long* input, usz length, char* output, usz output_capacity)
        @export("maximum_fenwick_tree") {
    if (input == null || length < 2 || length > 194 || input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 64) return -1;
    usz size = (usz)input[0], op_count = (usz)input[1];
    if (length != 2 + 3 * op_count) return -1;
    long[64] values = zeroed;
    long[64] tree = zeroed;
    long[64] results;
    usz result_count = 0;
    for (usz op = 0; op < op_count; op++) {
        usz pos = 2 + 3 * op;
        long opcode = input[pos], first = input[pos + 1], second = input[pos + 2];
        if (opcode == 0) {
            if (first < 0 || first >= (long)size || second < 0 || second > 2147483647L) return -1;
            usz index = (usz)first;
            long old_value = values[index], value = second;
            values[index] = value;
            while (index < size) {
                long old_max = tree[index];
                if (value > old_max) tree[index] = value;
                else if (old_value == old_max) {
                    usz left = (usz)(previous_bucket((long)index) + 1);
                    long maximum = value;
                    long child = (long)index - 1;
                    while (child >= (long)left) {
                        if (tree[(usz)child] > maximum) maximum = tree[(usz)child];
                        if (maximum == old_max) break;
                        child = previous_bucket(child);
                    }
                    tree[index] = maximum;
                    if (maximum == old_max) break;
                } else break;
                index |= index + 1;
            }
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > (long)size) return -1;
            long maximum = 0, right = second - 1;
            while (first <= right) {
                long current_left = right & (right + 1);
                if (first <= current_left) {
                    if (tree[(usz)right] > maximum) maximum = tree[(usz)right];
                    right = current_left - 1;
                } else {
                    if (values[(usz)right] > maximum) maximum = values[(usz)right];
                    right--;
                }
            }
            results[result_count++] = maximum;
        } else return -1;
    }
    usz bytes = result_count * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < result_count; i++) {
        ulong bits = (ulong)results[i];
        for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)((bits >> (8 * b)) & 255);
    }
    return (long)bytes;
}
