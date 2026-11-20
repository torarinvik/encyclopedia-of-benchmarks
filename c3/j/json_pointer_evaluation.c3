module json_pointer_evaluation;

const long MAX_NODES = 32;
const long MAX_POINTER = 64;
const usz RECORD_WORDS = 21;

long field(long *values, usz base, usz node, usz offset) {
    return values[base + node * RECORD_WORDS + offset];
}

long json_pointer_evaluation(long *values, usz length) @export("json_pointer_evaluation") {
    if (values == null || length < 3) return -1;
    long n_value = values[0], root_value = values[1], pointer_value = values[2];
    if (n_value < 1 || n_value > MAX_NODES || root_value < 0 || root_value >= n_value
            || pointer_value < 0 || pointer_value > MAX_POINTER) return -1;
    usz n = (usz)n_value, root = (usz)root_value, pointer_length = (usz)pointer_value;
    usz base = 3 + pointer_length;
    if (length != base + n * RECORD_WORDS) return -1;
    for (usz i = 0; i < pointer_length; i++)
        if (values[3 + i] < 0 || values[3 + i] > 127) return -1;
    if (pointer_length != 0 && values[3] != '/') return -1;
    for (usz syntax_pos = 1; syntax_pos < pointer_length; syntax_pos++) {
        if (values[3 + syntax_pos] != '~') continue;
        syntax_pos++;
        if (syntax_pos >= pointer_length) return -1;
        long escaped = values[3 + syntax_pos];
        if (escaped != '0' && escaped != '1') return -1;
    }

    for (usz i = 0; i < n; i++) {
        long kind = field(values, base, i, 0), parent = field(values, base, i, 1);
        long key_length = field(values, base, i, 2), array_index = field(values, base, i, 19);
        if (kind < 0 || kind > 2 || key_length < 0 || key_length > 16) return -1;
        if (i == root) {
            if (parent != -1 || key_length != 0 || array_index != -1) return -1;
        } else {
            if (parent < 0 || parent >= n_value || (usz)parent == i) return -1;
            long parent_kind = field(values, base, (usz)parent, 0);
            if (parent_kind < 0 || parent_kind > 1) return -1;
            if (parent_kind == 0) {
                if (array_index != -1) return -1;
            } else if (key_length != 0 || array_index < 0) return -1;
        }
        for (usz k = 0; k < 16; k++) {
            long ch = field(values, base, i, 3 + k);
            if (k < (usz)key_length) {
                if (ch < 0 || ch > 127) return -1;
            } else if (ch != 0) return -1;
        }
        usz cursor = i, hops = 0;
        while (cursor != root && hops < n) {
            long next = field(values, base, cursor, 1);
            if (next < 0 || next >= n_value) return -1;
            cursor = (usz)next;
            hops++;
        }
        if (cursor != root) return -1;
    }
    for (usz parent = 0; parent < n; parent++) {
        if (field(values, base, parent, 0) != 1) continue;
        usz children = 0;
        for (usz child = 0; child < n; child++)
            if (field(values, base, child, 1) == (long)parent) children++;
        for (usz child = 0; child < n; child++) {
            if (field(values, base, child, 1) != (long)parent) continue;
            long index = field(values, base, child, 19);
            if (index < 0 || (usz)index >= children) return -1;
            for (usz prior = 0; prior < child; prior++)
                if (field(values, base, prior, 1) == (long)parent
                        && field(values, base, prior, 19) == index) return -1;
        }
    }

    usz current = root;
    if (pointer_length == 0) return (long)current;
    long token[64] = {};
    usz token_length = 0, pos = 1;
    while (pos <= pointer_length) {
        if (pos == pointer_length || values[3 + pos] == '/') {
            long kind = field(values, base, current, 0);
            usz found = n, matches = 0;
            if (kind == 0) {
                for (usz child = 0; child < n; child++) {
                    if (field(values, base, child, 1) != (long)current
                            || field(values, base, child, 2) != (long)token_length) continue;
                    usz k = 0;
                    while (k < token_length && field(values, base, child, 3 + k) == token[k]) k++;
                    if (k == token_length) { found = child; matches++; }
                }
            } else if (kind == 1) {
                if (token_length == 0 || (token_length > 1 && token[0] == '0')) return -2;
                long index = 0;
                for (usz k = 0; k < token_length; k++) {
                    if (token[k] < '0' || token[k] > '9') return -2;
                    index = index * 10 + token[k] - '0';
                    if (index > MAX_NODES) return -2;
                }
                for (usz child = 0; child < n; child++)
                    if (field(values, base, child, 1) == (long)current
                            && field(values, base, child, 19) == index) { found = child; matches++; }
            } else return -2;
            if (matches != 1) return -2;
            current = found; token_length = 0; pos++;
            continue;
        }
        long ch = values[3 + pos];
        if (ch == '~') {
            pos++;
            if (pos >= pointer_length) return -1;
            long escaped = values[3 + pos];
            if (escaped == '0') ch = '~';
            else if (escaped == '1') ch = '/';
            else return -1;
        }
        token[token_length] = ch; token_length++; pos++;
    }
    return (long)current;
}
