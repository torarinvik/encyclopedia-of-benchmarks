module cubes_sequence;

fn long cubes_sequence(long index) @export("cubes_sequence") {
    if (index < 0 || index > 2097151) return -1;
    return index * index * index;
}
