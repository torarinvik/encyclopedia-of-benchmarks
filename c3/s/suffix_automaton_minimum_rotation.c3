// Uncompiled suffix-automaton minimum-rotation draft.
module suffix_automaton_minimum_rotation;
fn long suffix_automaton_minimum_rotation(long* input, usz length, char* output, usz capacity)
    @export("suffix_automaton_minimum_rotation") {
    if (input == null || length < 2 || length > 258) return -1;
    long raw_n = input[0];
    if (raw_n < 1 || raw_n > 256 || length != (usz)raw_n+1) return -1;
    usz n = (usz)raw_n;
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || capacity < n) return -2;
    int[262144] next = zeroed;
    int[1024] links = zeroed, lengths = zeroed;
    for (usz i = 0; i < 262144; i++) next[i] = -1;
    for (usz i = 0; i < 1024; i++) links[i] = -1;
    int count = 1, last = 0;
    for (usz i = 0; i < 2*n; i++) {
        int symbol = (int)input[1+i%n], current = count++;
        lengths[current] = lengths[last]+1;
        int p = last;
        while (p >= 0 && next[p*256+symbol] < 0) {
            next[p*256+symbol] = current; p = links[p];
        }
        if (p < 0) links[current] = 0;
        else {
            int q = next[p*256+symbol];
            if (lengths[p]+1 == lengths[q]) links[current] = q;
            else {
                int clone = count++;
                for (int c = 0; c < 256; c++) next[clone*256+c] = next[q*256+c];
                links[clone] = links[q]; lengths[clone] = lengths[p]+1;
                while (p >= 0 && next[p*256+symbol] == q) {
                    next[p*256+symbol] = clone; p = links[p];
                }
                links[q] = clone; links[current] = clone;
            }
        }
        last = current;
    }
    int state = 0;
    for (usz i = 0; i < n; i++) {
        int symbol = 0;
        while (next[state*256+symbol] < 0) symbol++;
        output[i] = (char)symbol; state = next[state*256+symbol];
    }
    return raw_n;
}
