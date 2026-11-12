module knuth_power_tree;

const usz MAX_TARGET = 127;
const usz MAX_OUTPUT_BYTES = 8 * (MAX_TARGET + 1);

fn usz build_path(usz target, usz* path) {
    if (target == 1) {
        path[0] = 1;
        return 1;
    }
    usz[MAX_TARGET + 1] parent = zeroed;
    bool[MAX_TARGET + 1] seen = zeroed;
    usz[MAX_TARGET + 1] queue = zeroed;
    usz[MAX_TARGET + 1] reverse = zeroed;
    usz head = 0, tail = 1;
    queue[0] = 1;
    seen[1] = true;
    while (head < tail) {
        usz current = queue[head++];
        usz chain_length = 0;
        for (usz node = current; node != 0; node = parent[node]) reverse[chain_length++] = node;
        for (usz offset = 0; offset < chain_length; offset++) {
            usz ancestor = reverse[chain_length - offset - 1];
            usz child = current + ancestor;
            if (child > target || seen[child]) continue;
            seen[child] = true;
            parent[child] = current;
            if (child == target) {
                usz count = 0;
                for (usz node = target; node != 0; node = parent[node]) path[count++] = node;
                for (usz left = 0, right = count - 1; left < right; left++, right--) {
                    usz temporary = path[left];
                    path[left] = path[right];
                    path[right] = temporary;
                }
                return count;
            }
            queue[tail++] = child;
        }
    }
    return 0;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long knuth_power_tree(long* input, usz length, char* output, usz output_capacity)
    @export("knuth_power_tree") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > (long)MAX_TARGET) return -1;
    usz target = (usz)input[0];
    usz[MAX_TARGET] path = zeroed;
    usz path_length = build_path(target, &path[0]);
    usz required = 8 * (path_length + 1);
    if (output == null || output_capacity < required) return -2;
    store_i64_le(output, 0, (long)(path_length - 1));
    for (usz index = 0; index < path_length; index++) store_i64_le(output, 8 * (index + 1), (long)path[index]);
    return (long)required;
}
