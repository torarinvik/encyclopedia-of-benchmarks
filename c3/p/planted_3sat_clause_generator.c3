module planted_3sat_clause_generator;

// Unverified deterministic planted 3-SAT generator draft.
fn long planted_3sat_clause_generator(long* input, usz length, char* output, usz capacity) @export("planted_3sat_clause_generator") {
    if (input == null || length < 5 || length > 83 || input[0] < 3 || input[0] > 16 || input[1] < 0 || input[1] > 32) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    if (length != 2+n+2*m) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    usz choices = n*(n-1)*(n-2)/6;
    long[96] literals;
    for (usz clause = 0; clause < m; clause++) {
        long raw = input[2+n+2*clause], mask = input[3+n+2*clause];
        if (raw < 0 || (ulong)raw >= choices || mask < 1 || mask > 7) return -1;
        usz rank = (usz)raw, next = 0;
        for (usz position = 0; position < 3; position++) {
            for (usz variable = next; variable < n-(2-position); variable++) {
                usz remaining = n-variable-1;
                usz ways = position == 0 ? remaining*(remaining-1)/2 : position == 1 ? remaining : 1;
                if (rank >= ways) { rank -= ways; continue; }
                long value = (long)(variable+1);
                literals[3*clause+position] = input[2+variable] == ((mask >> position) & 1) ? value : -value;
                next = variable+1;
                break;
            }
        }
    }
    usz bytes = 24*m;
    if (bytes > 0 && (output == null || capacity < bytes)) return -2;
    for (usz i = 0; i < 3*m; i++) {
        ulong bits = (ulong)literals[i];
        for (usz b = 0; b < 8; b++) output[8*i+b] = (char)(bits >> (8*b));
    }
    return (long)bytes;
}
