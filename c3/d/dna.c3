module dna;

const usz MAX_INPUT_VALUES = 1001;

fn long dna(long* values, usz length, char* output, usz output_capacity) @export("dna") {
    if (values == null || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0) return -1;
    usz count = length - 1;
    for (usz index = 1; index < length; index++) {
        long base = values[index];
        if (base != 'A' && base != 'T' && base != 'C' && base != 'G') return -1;
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        long base = values[index + 1];
        if (base == 'A') output[index] = 'T';
        else if (base == 'T') output[index] = 'A';
        else if (base == 'C') output[index] = 'G';
        else output[index] = 'C';
    }
    return (long)count;
}
