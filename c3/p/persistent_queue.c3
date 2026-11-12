module persistent_queue;

const usz MAX_Q = 128;
const usz TREE_BASE = 128;
const usz TREE_HEIGHT = 7;
const usz MAX_NODES = 1 + MAX_Q * (TREE_HEIGHT + 1);
const usz MAX_PARSEABLE_INPUT = 1 + 3 * MAX_Q + 1;
const long MAX_VALUE = 1000000000;

struct Node { usz left; usz right; long value; }

fn usz set_value(Node[MAX_NODES]* nodes, usz* used, usz root,
                 usz low, usz high, usz position, long value) {
    usz copy = *used;
    *used += 1;
    nodes[copy] = nodes[root];
    if (high - low == 1) {
        nodes[copy].value = value;
        return copy;
    }
    usz middle = low + (high - low) / 2;
    if (position < middle) {
        usz child = set_value(nodes, used, nodes[root].left, low, middle, position, value);
        nodes[copy].left = child;
    } else {
        usz child = set_value(nodes, used, nodes[root].right, middle, high, position, value);
        nodes[copy].right = child;
    }
    return copy;
}

fn long get_value(Node[MAX_NODES]* nodes, usz root,
                  usz low, usz high, usz position) {
    if (high - low == 1) return nodes[root].value;
    usz middle = low + (high - low) / 2;
    if (position < middle)
        return get_value(nodes, nodes[root].left, low, middle, position);
    return get_value(nodes, nodes[root].right, middle, high, position);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long persistent_queue(long* input, usz length, char* output, usz capacity)
    @export("persistent_queue") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_Q) return -1;
    usz q = (usz)input[0];
    long[MAX_Q] kind, parent, value;
    usz[MAX_Q + 1] version_head = zeroed, version_tail = zeroed, version_size = zeroed;
    usz cursor = 1, pop_count = 0;
    for (usz operation = 0; operation < q; operation += 1) {
        if (cursor + 2 > length) return -1;
        kind[operation] = input[cursor];
        cursor += 1;
        parent[operation] = input[cursor];
        cursor += 1;
        if ((kind[operation] != 0 && kind[operation] != 1) || parent[operation] < -1 ||
            parent[operation] >= (long)operation) return -1;
        usz base = (usz)(parent[operation] + 1);
        if (kind[operation] == 0) {
            if (cursor >= length) return -1;
            value[operation] = input[cursor];
            cursor += 1;
            if (value[operation] < 0 || value[operation] > MAX_VALUE || version_tail[base] >= TREE_BASE)
                return -1;
            version_head[operation + 1] = version_head[base];
            version_tail[operation + 1] = version_tail[base] + 1;
            version_size[operation + 1] = version_size[base] + 1;
        } else {
            if (version_size[base] == 0) return -1;
            version_head[operation + 1] = version_head[base] + 1;
            version_tail[operation + 1] = version_tail[base];
            version_size[operation + 1] = version_size[base] - 1;
            pop_count += 1;
        }
    }
    if (cursor != length) return -1;
    usz output_bytes = 8 * pop_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;

    Node[MAX_NODES] nodes = zeroed;
    usz[MAX_Q + 1] roots = zeroed;
    long[MAX_Q] answers;
    usz answer_count = 0, used = 1;
    for (usz operation = 0; operation < q; operation += 1) {
        usz base = (usz)(parent[operation] + 1);
        usz version = operation + 1;
        if (kind[operation] == 0) {
            roots[version] = set_value(&nodes, &used, roots[base], 0, TREE_BASE,
                                       version_tail[base], value[operation]);
        } else {
            answers[answer_count] = get_value(&nodes, roots[base], 0, TREE_BASE,
                                              version_head[base]);
            answer_count += 1;
            roots[version] = roots[base];
        }
    }
    for (usz index = 0; index < answer_count; index += 1)
        store_i64_le(output, 8 * index, answers[index]);
    return (long)output_bytes;
}
