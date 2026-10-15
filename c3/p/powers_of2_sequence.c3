module powers_of2_sequence;

// Return a term from the bounded powers-of-two sequence.
fn long powers_of2_sequence(long index) @export("powers_of2_sequence") {
    if (index < 0 || index > 62) return -1;
    long value = 1;
    for (long step = 0; step < index; step += 1) value *= 2;
    return value;
}
