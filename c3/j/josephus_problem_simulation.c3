module josephus_problem_simulation;
fn long josephus_problem_simulation(long* values, usz length) @export("josephus_problem_simulation") {
    if (length != 2) return -1;
    long n = values[0];
    long step = values[1];
    if (n < 1 || n > 512 || step < 1) return -1;
    long[512] people;
    usz remaining = (usz)n;
    for (usz i = 0; i < remaining; i++) people[i] = (long)i + 1;
    usz current = 0;
    while (remaining > 1) {
        usz offset = (usz)((step - 1) % (long)remaining);
        usz removed = (current + offset) % remaining;
        for (usz i = removed; i + 1 < remaining; i++) people[i] = people[i + 1];
        remaining--;
        current = removed % remaining;
    }
    return people[0];
}
