module key_priority_queue;

fn usz find_key(long* keys, usz count, long key) {
    for (usz i = 0; i < count; i++) if (keys[i] == key) return i;
    return count;
}
fn void swap_items(long* keys, long* priorities, usz a, usz b) {
    long t = keys[a]; keys[a] = keys[b]; keys[b] = t;
    t = priorities[a]; priorities[a] = priorities[b]; priorities[b] = t;
}
fn void shift_up(long* keys, long* priorities, usz i) {
    while (i > 0) { usz p = (i - 1) / 2; if (priorities[p] <= priorities[i]) break; swap_items(keys, priorities, p, i); i = p; }
}
fn void shift_down(long* keys, long* priorities, usz n, usz i) {
    while (2 * i + 1 < n) { usz l = 2 * i + 1, r = l + 1, c;
        if (priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r])) c = l;
        else if (r < n && priorities[r] < priorities[i]) c = r; else break;
        swap_items(keys, priorities, i, c); i = c;
    }
}
long key_priority_queue(long* input, usz length, char* output, usz output_capacity)
        @export("key_priority_queue") {
    if (input == null || length < 1 || length > 98 || input[0] < 0 || input[0] > 32) return -1;
    long keys[32], priorities[32], answers[32]; usz n = 0, out_n = 0, pos = 1;
    for (usz opi = 0; opi < (usz)input[0]; opi++) {
        if (pos >= length) return -1;
        long op = input[pos];
        if (op == 0 || op == 1) {
            if (pos + 2 >= length) return -1;
            long key = input[pos + 1], priority = input[pos + 2];
            if (key < -1000000000L || key > 1000000000L || priority < -1000000000L || priority > 1000000000L) return -1;
            pos += 3; usz found = find_key(keys, n, key);
            if (op == 0) { if (found != n) return -1; keys[n] = key; priorities[n] = priority; shift_up(keys, priorities, n); n++; }
            else if (found == n) { keys[n] = key; priorities[n] = priority; shift_up(keys, priorities, n); n++; }
            else { priorities[found] = priority;
                if (found > 0 && priorities[(found - 1) / 2] > priority) shift_up(keys, priorities, found);
                else { usz l = 2 * found + 1, r = l + 1; if ((l < n && priorities[l] < priority) || (r < n && priorities[r] < priority)) shift_down(keys, priorities, n, found); }
            }
        } else if (op == 2) { pos++; if (n == 0) return -1; swap_items(keys, priorities, 0, n - 1); n--; answers[out_n++] = keys[n]; if (n > 0) shift_down(keys, priorities, n, 0); }
        else if (op == 3) { if (pos + 1 >= length) return -1; long key = input[pos + 1]; if (key < -1000000000L || key > 1000000000L) return -1; pos += 2; answers[out_n++] = find_key(keys, n, key) != n ? 1 : 0; }
        else if (op == 4) { pos++; answers[out_n++] = n == 0 ? 1 : 0; }
        else return -1;
    }
    if (pos != length) return -1;
    usz bytes = out_n * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < out_n; i++) { ulong bits = (ulong)answers[i]; for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)((bits >> (8 * b)) & 255); }
    return (long)bytes;
}
