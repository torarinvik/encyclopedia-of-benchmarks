module cyclic_sort;

const usz MAX_LENGTH = 1024;

fn long cyclic_sort(long* values, usz length, char* output, usz output_capacity)
    @export("cyclic_sort") {
    if (length > MAX_LENGTH || (length > 0 && values == null)) return -1;
    bool[MAX_LENGTH + 1] seen;
    for (usz index = 0; index <= length; index++) seen[index] = false;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 1 || value > (long)length || seen[(usz)value]) return -1;
        seen[(usz)value] = true;
    }

    long[MAX_LENGTH] sorted;
    for (usz index = 0; index < length; index++) sorted[index] = values[index];
    usz index = 0;
    while (index < length) {
        usz destination = (usz)(sorted[index] - 1);
        if (destination == index) {
            index++;
        } else {
            long temporary = sorted[index];
            sorted[index] = sorted[destination];
            sorted[destination] = temporary;
        }
    }

    usz output_length = length * 8;
    if (output_length > output_capacity || (output_length > 0 && output == null)) return -2;
    for (usz item = 0; item < length; item++) {
        ulong bits = (ulong)sorted[item];
        for (usz byte = 0; byte < 8; byte++) {
            output[item * 8 + byte] = (char)(bits >> (8 * byte));
        }
    }
    return (long)length;
}
