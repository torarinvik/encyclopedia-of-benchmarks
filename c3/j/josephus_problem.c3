module josephus_problem;
fn long josephus_problem(long* values, usz length) @export("josephus_problem") {
    if (length != 2) return -1;
    long n = values[0];
    long step = values[1];
    if (n < 1 || n > 100000 || step < 1) return -1;
    long winner = 0;
    for (long size = 1; size <= n; size++) winner = (winner + step % size) % size;
    return winner + 1;
}
