module cactus_stack_branch_trace;

const QMAX = 48; const HANDLES = 8; const WORD_MAX = 145;
fn void put(u8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz j = 0; j < 8; j++) output[offset + j] = (u8)((bits >> (8 * j)) & 255);
}

fn long cactus_stack_branch_trace(long* input, usz length, u8* output, usz output_capacity)
    @export("cactus_stack_branch_trace") {
    if (input == null || length < 1 || length > WORD_MAX + 1) return -1;
    if (input[0] < 0 || input[0] > QMAX || length != 1 + 3 * (usz)input[0]) return -1;
    usz q = (usz)input[0];
    for (usz i = 0; i < q; i++) {
        long op = input[1 + 3*i], a = input[2 + 3*i], b = input[3 + 3*i];
        if (op == 0) { if (a < 0 || a >= HANDLES || b < -1000 || b > 1000) return -1; }
        else if (op >= 1 && op <= 3) { if (a < 0 || a >= HANDLES || b != 0) return -1; }
        else if (op == 4) { if (a < 0 || a >= HANDLES || b < 0 || b >= HANDLES) return -1; }
        else return -1;
    }

    long[48] node_value, node_next, node_child, node_kind, node_live;
    long[8] heads, branch_child, attached_owner, wrapper_for_child;
    long[48] statuses, results;
    for (usz h = 0; h < HANDLES; h++) {
        heads[h] = -1; branch_child[h] = -1; attached_owner[h] = -1; wrapper_for_child[h] = -1;
    }
    usz node_count = 0;
    for (usz i = 0; i < q; i++) {
        long op = input[1 + 3*i], a = input[2 + 3*i], b = input[3 + 3*i];
        usz h = (usz)a;
        long head = heads[h];
        while (head >= 0 && node_kind[(usz)head] == 1 && node_live[(usz)head] == 0) head = node_next[(usz)head];
        heads[h] = head; statuses[i] = 1; results[i] = 0;
        if (op == 0) {
            node_value[node_count] = b; node_next[node_count] = head; node_child[node_count] = -1;
            node_kind[node_count] = 0; node_live[node_count] = 0; heads[h] = (long)node_count; node_count++;
        } else if (op == 1) {
            if (head < 0 || (node_kind[(usz)head] == 1 && node_live[(usz)head] != 0)) statuses[i] = 0;
            else {
                results[i] = node_value[(usz)head];
                long next = node_next[(usz)head];
                while (next >= 0 && node_kind[(usz)next] == 1 && node_live[(usz)next] == 0) next = node_next[(usz)next];
                heads[h] = next;
                if (next < 0 && attached_owner[h] >= 0) {
                    usz owner = (usz)attached_owner[h];
                    node_live[(usz)wrapper_for_child[h]] = 0; branch_child[owner] = -1;
                    attached_owner[h] = -1; wrapper_for_child[h] = -1;
                }
            }
        } else if (op == 2) {
            long top = head;
            while (top >= 0 && node_kind[(usz)top] == 1) {
                top = node_next[(usz)top];
                while (top >= 0 && node_kind[(usz)top] == 1 && node_live[(usz)top] == 0) top = node_next[(usz)top];
            }
            if (top < 0) statuses[i] = 0; else results[i] = node_value[(usz)top];
        } else if (op == 3) {
            if (head >= 0 && node_kind[(usz)head] == 1 && node_live[(usz)head] != 0) results[i] = 1;
        } else {
            usz child = (usz)b;
            long child_head = heads[child];
            while (child_head >= 0 && node_kind[(usz)child_head] == 1 && node_live[(usz)child_head] == 0) child_head = node_next[(usz)child_head];
            heads[child] = child_head;
            long top = head;
            while (top >= 0 && node_kind[(usz)top] == 1) {
                top = node_next[(usz)top];
                while (top >= 0 && node_kind[(usz)top] == 1 && node_live[(usz)top] == 0) top = node_next[(usz)top];
            }
            if (a == b || top < 0 || attached_owner[h] >= 0 || branch_child[h] >= 0
                || attached_owner[child] >= 0 || branch_child[child] >= 0) return -1;
            if (child_head < 0) results[i] = 0;
            else {
                node_value[node_count] = 0; node_next[node_count] = head; node_child[node_count] = (long)child;
                node_kind[node_count] = 1; node_live[node_count] = 1;
                usz wrapper = node_count; node_count++; heads[h] = (long)wrapper;
                branch_child[h] = (long)child; attached_owner[child] = a; wrapper_for_child[child] = (long)wrapper;
                results[i] = 1;
            }
        }
    }
    usz bytes = 16 * q;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < q; i++) { put(output, 16*i, statuses[i]); put(output, 16*i+8, results[i]); }
    return (long)bytes;
}
