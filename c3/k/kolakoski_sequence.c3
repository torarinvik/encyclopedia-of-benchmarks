module kolakoski_sequence;

const long MAX_INDEX = 63L;

fn long kolakoski_sequence(long index) @export("kolakoski_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;

    ulong encoded = 6ul;
    ulong read_bit = 4ul;
    ulong write_bit = 8ul;
    ulong target = (ulong)index;
    ulong current_index = 3ul;
    long next_element = 1;

    while (current_index <= target) {
        ulong run_length = 1ul + (encoded / read_bit) % 2ul;
        for (ulong emitted = 0; emitted < run_length; emitted += 1) {
            if (next_element == 2) encoded += write_bit;
            if (current_index == target) return next_element;
            current_index += 1;
            write_bit *= 2ul;
        }
        read_bit *= 2ul;
        next_element = 3 - next_element;
    }
    return -1;
}
