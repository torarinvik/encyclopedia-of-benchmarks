module zero_sequence;

fn long zero_sequence(long index) @export("zero_sequence") {
    if (index < 0) return -1;
    return 0;
}
