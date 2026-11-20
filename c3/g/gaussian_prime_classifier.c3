module gaussian_prime_classifier;

const long MAX_COORDINATE = 10000;

fn bool gp_rational_prime(long value) {
	if (value < 2) return false;
	if (value % 2 == 0) return value == 2;
	for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
		if (value % divisor == 0) return false;
	}
	return true;
}

fn long gaussian_prime_classifier(long* input, usz length) @export("gaussian_prime_classifier") {
	if (input == null || length < 1 || length > 3) return -1;
	if (length != 2) return -1;
	long real = input[0];
	long imaginary = input[1];
	if (real < -MAX_COORDINATE || real > MAX_COORDINATE ||
		imaginary < -MAX_COORDINATE || imaginary > MAX_COORDINATE) return -1;
	if (real == 0 && imaginary == 0) return 0;
	if (real == 0 || imaginary == 0) {
		long axis = real == 0 ? imaginary : real;
		long rational = axis < 0 ? -axis : axis;
		if (rational % 4 == 3 && gp_rational_prime(rational)) return 1;
		return 0;
	}
	long norm = real * real + imaginary * imaginary;
	if (gp_rational_prime(norm)) return 1;
	return 0;
}
