module tower_of_hanoi;

fn usz emit_hanoi(usz disks, char source, char destination, char auxiliary,
                  char* output, usz position)
{
    if (disks == 0) return position;
    position = emit_hanoi(disks - 1, source, auxiliary, destination, output, position);
    output[position] = source;
    output[position + 1] = destination;
    return emit_hanoi(disks - 1, auxiliary, destination, source, output, position + 2);
}

fn long tower_of_hanoi(long* values, usz length, char* output, usz output_capacity)
    @export("tower_of_hanoi")
{
    if (values == null || length != 4 || values[0] < 0 || values[0] > 12) return -1;
    for (usz index = 1; index < 4; index++) {
        if (values[index] < 0 || values[index] > 2) return -1;
    }
    if (values[1] == values[2] || values[1] == values[3] || values[2] == values[3]) return -1;
    usz disks = (usz)values[0];
    usz move_count = ((usz)1 << disks) - 1;
    usz required = move_count * 2;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    emit_hanoi(disks, (char)values[1], (char)values[2], (char)values[3], output, 0);
    return (long)move_count;
}
