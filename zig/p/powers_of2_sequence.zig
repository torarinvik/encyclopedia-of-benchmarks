/// Return a term from the bounded powers-of-two sequence.
export fn powers_of2_sequence(index: i64) i64 {
    if (index < 0 or index > 62) return -1;
    var value: i64 = 1;
    var step: i64 = 0;
    while (step < index) : (step += 1) value *= 2;
    return value;
}
