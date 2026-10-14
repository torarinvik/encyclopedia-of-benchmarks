/// Stable gnome sort for the shared mutable in-place sorting contract.
export fn gnome_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var position: usize = 1;
    while (position < length) {
        if (values[position] >= values[position - 1]) {
            position += 1;
        } else {
            const temporary = values[position - 1];
            values[position - 1] = values[position];
            values[position] = temporary;
            if (position > 1) {
                position -= 1;
            } else {
                position = 1;
            }
        }
    }
}
