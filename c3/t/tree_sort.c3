module tree_sort;

const MAX_VALUES = 1024;

fn void tree_sort(long* values, usz length) @export("tree_sort") {
    if (length > MAX_VALUES) return;
    long[MAX_VALUES] keys;
    usz[MAX_VALUES] left, right, stack;
    usz empty = length;
    usz root = empty;
    for (usz index = 0; index < length; index++) {
        keys[index] = values[index]; left[index] = empty; right[index] = empty;
        if (root == empty) { root = index; continue; }
        usz node = root;
        while (true) {
            if (keys[index] < keys[node]) {
                if (left[node] == empty) { left[node] = index; break; }
                node = left[node];
            } else {
                if (right[node] == empty) { right[node] = index; break; }
                node = right[node];
            }
        }
    }
    usz current = root;
    usz stack_size = 0;
    usz output = 0;
    while (current != empty || stack_size > 0) {
        while (current != empty) { stack[stack_size++] = current; current = left[current]; }
        current = stack[--stack_size];
        values[output++] = keys[current];
        current = right[current];
    }
}
