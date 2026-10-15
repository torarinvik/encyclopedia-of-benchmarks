module natural_sequence;

fn long natural_sequence(long index) @export("natural_sequence") {
    if (index < 0 || index == 9223372036854775807L) return -1;
    return index + 1;
}
