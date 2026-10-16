module problem122;

fn bool solve(long* chain, usz length, long goal, usz depth) {
    long last = chain[length - 1];
    for (usz index = 0; index < length; index++) {
        long next = chain[index] + last;
        if (next == goal) return true;
        if (next > goal) break;
        if (length < depth) {
            chain[length] = next;
            if (solve(chain, length + 1, goal, depth)) return true;
        }
    }
    return false;
}

fn long problem122(long maximum) @export("problem122") {
    if (maximum < 0 || maximum > 200) return -1;
    long total = 0;
    for (long goal = 2; goal <= maximum; goal++) {
        usz depth = 0;
        long[32] chain = {1};
        while (true) { depth++; chain[0] = 1; if (solve(&chain[0], 1, goal, depth)) break; }
        total += (long)depth;
    }
    return total;
}
