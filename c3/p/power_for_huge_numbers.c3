module power_for_huge_numbers;

const usz MAX_OUTPUT_BYTES = 513;

fn long power_for_huge_numbers(long* input, usz length, char* output, usz capacity)
		@export("power_for_huge_numbers") {
	if (input == null || length != 2) return -1;
	long base = input[0], exponent = input[1];
	if (base < 1 || base > 10000 || exponent < 0 || exponent > 128) return -1;

	u8 digits[MAX_OUTPUT_BYTES] = {0};
	digits[0] = 1;
	usz digit_count = 1;
	for (long power = 0; power < exponent; power++) {
		long carry = 0;
		for (usz i = 0; i < digit_count; i++) {
			long product = (long)digits[i] * base + carry;
			digits[i] = (u8)(product % 10);
			carry = product / 10;
		}
		while (carry != 0) {
			if (digit_count == MAX_OUTPUT_BYTES) return -1;
			digits[digit_count++] = (u8)(carry % 10);
			carry /= 10;
		}
	}
	if (output == null || capacity < digit_count) return -2;
	for (usz i = 0; i < digit_count; i++) output[i] = (char)(48 + digits[digit_count - 1 - i]);
	return (long)digit_count;
}
