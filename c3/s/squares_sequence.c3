module squares_sequence;

const long MAX_INDEX = 3037000499L;

fn long squares_sequence(long index) @export("squares_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    return index * index;
}
