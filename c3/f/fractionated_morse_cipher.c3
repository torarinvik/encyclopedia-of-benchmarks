module fractionated_morse_cipher;

const u8[26] MORSE_CODE = {1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12};
const usz[26] MORSE_LENGTH = {2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4};
const char[3] MORSE_SYMBOLS = {'.','-','x'};

fn void make_keyed_alphabet(long* input, usz key_start, usz key_length, char* keyed) {
	bool seen[26] = {0};
	usz count = 0;
	for (usz i = 0; i < key_length; i++) {
		long value = input[key_start + i];
		if (value >= 'a' && value <= 'z') value -= 32;
		usz letter = (usz)(value - 'A');
		if (!seen[letter]) { seen[letter] = true; keyed[count++] = (char)value; }
	}
	for (usz letter = 0; letter < 26; letter++)
		if (!seen[letter]) keyed[count++] = (char)('A' + letter);
}

fn long morse_letter(char* morse, usz start, usz length) {
	if (length < 1 || length > 4) return -1;
	usz code = 0;
	for (usz i = 0; i < length; i++) code = code * 2 + (morse[start + i] == '-');
	for (usz letter = 0; letter < 26; letter++)
		if (MORSE_LENGTH[letter] == length && MORSE_CODE[letter] == code) return (long)letter;
	return -1;
}

fn long fractionated_morse_cipher(long* input, usz length, char* output, usz output_capacity)
		@export("fractionated_morse_cipher") {
	if (input == null || length < 3 || length > 323) return -1;
	long mode = input[0], text_value = input[1], key_value = input[2];
	if ((mode != 0 && mode != 1) || text_value < 0 || text_value > 256 || key_value < 0 || key_value > 64) return -1;
	usz text_length = (usz)text_value, key_length = (usz)key_value;
	if (length != 3 + text_length + key_length) return -1;
	usz key_start = 3 + text_length;
	for (usz i = 0; i < key_length; i++) {
		long value = input[key_start + i];
		if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
	}
	for (usz i = 0; i < text_length; i++) {
		long value = input[3 + i];
		if (mode == 0) {
			if (value != ' ' && !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
		} else if (value < 'A' || value > 'Z') return -1;
	}
	char keyed[26];
	make_keyed_alphabet(input, key_start, key_length, keyed);
	char result[800] = {0};
	usz result_length = 0;
	if (mode == 0) {
		char morse[1300] = {0};
		usz morse_length = 0;
		for (usz i = 0; i < text_length; i++) {
			if (i != 0) morse[morse_length++] = 'x';
			long value = input[3 + i];
			if (value == ' ') continue;
			if (value >= 'a' && value <= 'z') value -= 32;
			usz letter = (usz)(value - 'A');
			for (usz bit = 0; bit < MORSE_LENGTH[letter]; bit++) {
				usz mask = (usz)1 << (MORSE_LENGTH[letter] - bit - 1);
				morse[morse_length++] = (MORSE_CODE[letter] & mask) != 0 ? '-' : '.';
			}
		}
		usz padding = 3 - morse_length % 3;
		for (usz i = 0; i < padding; i++) morse[morse_length++] = 'x';
		for (usz start = 0; start < morse_length; start += 3) {
			usz trigram = 0;
			for (usz offset = 0; offset < 3; offset++) {
				usz digit = morse[start + offset] == '.' ? 0 : morse[start + offset] == '-' ? 1 : 2;
				trigram = trigram * 3 + digit;
			}
			if (trigram < 26) result[result_length++] = keyed[trigram];
		}
	} else {
		char morse[1300] = {0};
		usz morse_length = 0;
		for (usz i = 0; i < text_length; i++) {
			usz trigram = 0;
			while (trigram < 26 && keyed[trigram] != (char)input[3 + i]) trigram++;
			if (trigram == 26) return -1;
			morse[morse_length++] = MORSE_SYMBOLS[trigram / 9];
			morse[morse_length++] = MORSE_SYMBOLS[(trigram / 3) % 3];
			morse[morse_length++] = MORSE_SYMBOLS[trigram % 3];
		}
		usz segment_start = 0;
		for (usz i = 0; i <= morse_length; i++) {
			if (i != morse_length && morse[i] != 'x') continue;
			usz segment_length = i - segment_start;
			if (segment_length == 0) result[result_length++] = ' ';
			else {
				long letter = morse_letter(morse, segment_start, segment_length);
				if (letter < 0) return -1;
				result[result_length++] = (char)('A' + letter);
			}
			segment_start = i + 1;
		}
		usz first = 0;
		while (first < result_length && result[first] == ' ') first++;
		while (result_length > first && result[result_length - 1] == ' ') result_length--;
		if (first != 0) {
			for (usz i = first; i < result_length; i++) result[i - first] = result[i];
			result_length -= first;
		}
	}
	if (output_capacity < result_length || (result_length != 0 && output == null)) return -2;
	for (usz i = 0; i < result_length; i++) output[i] = result[i];
	return (long)result_length;
}
