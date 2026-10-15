module dna2_rna;

const usz MAX_INPUT_VALUES = 1001;

fn long dna2_rna(long* values, usz length, char* output, usz output_capacity)
        @export("dna2_rna") {
    if (values == null || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0) return -1;
    usz count = length - 1;
    for (usz index = 1; index < length; index++)
        if (values[index] < 'A' || values[index] > 'Z') return -1;
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        long base = values[index + 1];
        output[index] = (char)(base == 'T' ? 'U' : base);
    }
    return (long)count;
}
