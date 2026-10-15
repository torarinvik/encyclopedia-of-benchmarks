module reverse_complement;

const usz MAX_REVERSE_COMPLEMENT_LENGTH = 1000;

fn long reverse_complement(long* input, usz length, char* output, usz output_capacity)
		@export("reverse_complement") {
	if (length > MAX_REVERSE_COMPLEMENT_LENGTH || (length != 0 && input == null)) return -1;
	for (usz i = 0; i < length; i++) {
		long base = input[i];
		if (base != 'A' && base != 'C' && base != 'G' && base != 'T') return -1;
	}
	if (output_capacity < length || (length != 0 && output == null)) return -2;
	for (usz i = 0; i < length; i++) {
		long base = input[length - 1 - i];
		output[i] = (char)(base == 'A' ? 'T' : base == 'T' ? 'A' : base == 'C' ? 'G' : 'C');
	}
	return (long)length;
}
