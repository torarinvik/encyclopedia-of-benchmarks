module autokey_cipher;

const usz MAX_AUTOKEY_LENGTH = 1024;

fn long uppercase_letter(long value) {
	return value >= 'a' && value <= 'z' ? value - 32 : value;
}

fn long autokey_cipher(long* input, usz length, char* output, usz output_capacity)
		@export("autokey_cipher") {
	if (input == null || length < 6 || length > 4 + 2 * MAX_AUTOKEY_LENGTH) return -1;
	long mode = input[0];
	long dialect = input[1];
	long text_length_value = input[2];
	long key_length_value = input[3];
	if ((mode != 0 && mode != 1) || (dialect != 0 && dialect != 1)
		|| text_length_value < 1 || text_length_value > MAX_AUTOKEY_LENGTH
		|| key_length_value < 1 || key_length_value > MAX_AUTOKEY_LENGTH) return -1;
	usz text_length = (usz)text_length_value;
	usz key_length = (usz)key_length_value;
	if (length != 4 + text_length + key_length) return -1;
	usz key_start = 4 + text_length;
	for (usz i = 0; i < text_length; i++) {
		long value = input[4 + i];
		if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
		if (dialect == 1 && mode == 1 && value >= 'A' && value <= 'Z') return -1;
	}
	for (usz i = 0; i < key_length; i++) {
		long value = input[key_start + i];
		if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
	}
	if (output_capacity < text_length || output == null) return -2;
	for (usz i = 0; i < text_length; i++) {
		long plain = uppercase_letter(input[4 + i]) - 'A';
		long key_value = i < key_length ? uppercase_letter(input[key_start + i])
			: mode == 0 ? uppercase_letter(input[4 + i - key_length]) : uppercase_letter(output[i - key_length]);
		long shift = key_value - 'A';
		long mapped = mode == 0 ? (plain + shift) % 26 : (plain - shift + 26) % 26;
		long result = 'A' + mapped;
		if (dialect == 1) result += 32;
		output[i] = (char)result;
	}
	return (long)text_length;
}
