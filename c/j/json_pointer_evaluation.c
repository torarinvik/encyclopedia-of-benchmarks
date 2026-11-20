#include <stddef.h>
#include <stdint.h>

enum { MAX_NODES = 32, MAX_POINTER = 64, RECORD_WORDS = 21 };

static int64_t field(const int64_t *values, size_t base, size_t node, size_t offset)
{
    return values[base + node * RECORD_WORDS + offset];
}

int64_t json_pointer_evaluation(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return -1;
    const int64_t node_count_value = values[0];
    const int64_t root_value = values[1];
    const int64_t pointer_length_value = values[2];
    if (node_count_value < 1 || node_count_value > MAX_NODES
            || root_value < 0 || root_value >= node_count_value
            || pointer_length_value < 0 || pointer_length_value > MAX_POINTER) return -1;
    const size_t node_count = (size_t)node_count_value;
    const size_t root = (size_t)root_value;
    const size_t pointer_length = (size_t)pointer_length_value;
    const size_t base = 3 + pointer_length;
    if (length != base + node_count * RECORD_WORDS) return -1;
    for (size_t i = 0; i < pointer_length; ++i) {
        if (values[3 + i] < 0 || values[3 + i] > 127) return -1;
    }
    if (pointer_length != 0 && values[3] != '/') return -1;
    for (size_t syntax_pos = 1; syntax_pos < pointer_length; ++syntax_pos) {
        if (values[3 + syntax_pos] != '~') continue;
        if (++syntax_pos >= pointer_length) return -1;
        const int64_t escaped = values[3 + syntax_pos];
        if (escaped != '0' && escaped != '1') return -1;
    }

    for (size_t i = 0; i < node_count; ++i) {
        const int64_t kind = field(values, base, i, 0);
        const int64_t parent = field(values, base, i, 1);
        const int64_t key_length = field(values, base, i, 2);
        const int64_t array_index = field(values, base, i, 19);
        if (kind < 0 || kind > 2 || key_length < 0 || key_length > 16) return -1;
        if (i == root) {
            if (parent != -1 || key_length != 0 || array_index != -1) return -1;
        } else {
            if (parent < 0 || parent >= node_count_value || (size_t)parent == i) return -1;
            const int64_t parent_kind = field(values, base, (size_t)parent, 0);
            if (parent_kind < 0 || parent_kind > 1) return -1;
            if (parent_kind == 0) {
                if (array_index != -1) return -1;
            } else if (key_length != 0 || array_index < 0) return -1;
        }
        for (size_t k = 0; k < 16; ++k) {
            const int64_t ch = field(values, base, i, 3 + k);
            if (k < (size_t)key_length) {
                if (ch < 0 || ch > 127) return -1;
            } else if (ch != 0) return -1;
        }
        size_t cursor = i;
        size_t hops = 0;
        while (cursor != root && hops < node_count) {
            const int64_t next = field(values, base, cursor, 1);
            if (next < 0 || next >= node_count_value) return -1;
            cursor = (size_t)next;
            ++hops;
        }
        if (cursor != root) return -1;
    }

    for (size_t parent = 0; parent < node_count; ++parent) {
        if (field(values, base, parent, 0) != 1) continue;
        size_t children = 0;
        for (size_t child = 0; child < node_count; ++child)
            if (field(values, base, child, 1) == (int64_t)parent) ++children;
        for (size_t child = 0; child < node_count; ++child) {
            if (field(values, base, child, 1) != (int64_t)parent) continue;
            const int64_t index = field(values, base, child, 19);
            if (index < 0 || (uint64_t)index >= children) return -1;
            for (size_t prior = 0; prior < child; ++prior)
                if (field(values, base, prior, 1) == (int64_t)parent
                        && field(values, base, prior, 19) == index) return -1;
        }
    }

    size_t current = root;
    if (pointer_length == 0) return (int64_t)current;
    int64_t token[MAX_POINTER];
    size_t token_length = 0;
    for (size_t pos = 1; pos <= pointer_length; ++pos) {
        if (pos == pointer_length || values[3 + pos] == '/') {
            const int64_t kind = field(values, base, current, 0);
            size_t found = node_count;
            size_t matches = 0;
            if (kind == 0) {
                for (size_t child = 0; child < node_count; ++child) {
                    if (field(values, base, child, 1) != (int64_t)current
                            || field(values, base, child, 2) != (int64_t)token_length) continue;
                    size_t k = 0;
                    while (k < token_length
                            && field(values, base, child, 3 + k) == token[k]) ++k;
                    if (k == token_length) { found = child; ++matches; }
                }
            } else if (kind == 1) {
                if (token_length == 0 || (token_length > 1 && token[0] == '0')) return -2;
                int64_t index = 0;
                for (size_t k = 0; k < token_length; ++k) {
                    if (token[k] < '0' || token[k] > '9') return -2;
                    index = index * 10 + token[k] - '0';
                    if (index > MAX_NODES) return -2;
                }
                for (size_t child = 0; child < node_count; ++child)
                    if (field(values, base, child, 1) == (int64_t)current
                            && field(values, base, child, 19) == index) {
                        found = child; ++matches;
                    }
            } else return -2;
            if (matches != 1) return -2;
            current = found;
            token_length = 0;
            continue;
        }
        int64_t ch = values[3 + pos];
        if (ch == '~') {
            if (++pos >= pointer_length) return -1;
            const int64_t escaped = values[3 + pos];
            if (escaped == '0') ch = '~';
            else if (escaped == '1') ch = '/';
            else return -1;
        }
        token[token_length++] = ch;
    }
    return (int64_t)current;
}
