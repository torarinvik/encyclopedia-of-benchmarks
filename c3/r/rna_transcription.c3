module rna_transcription;

const usz MAX_INPUT_VALUES = 1001;

fn long rna_transcription(long* values, usz length, char* output, usz output_capacity)
        @export("rna_transcription") {
    if (values == null || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0) return -1;
    usz count = length - 1;
    for (usz index = 1; index < length; index++) {
        long base = values[index];
        if (base != 'A' && base != 'C' && base != 'G' && base != 'T') return -1;
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        long base = values[index + 1];
        if (base == 'A') output[index] = 'U';
        else if (base == 'C') output[index] = 'G';
        else if (base == 'G') output[index] = 'C';
        else output[index] = 'A';
    }
    return (long)count;
}
