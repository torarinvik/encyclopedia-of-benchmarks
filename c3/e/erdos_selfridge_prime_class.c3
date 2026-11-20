module erdos_selfridge_prime_class;

const long ES_MAX_PRIME = 100000;

fn bool es_is_prime(long value) {
	if (value < 2) return false;
	if (value % 2 == 0) return value == 2;
	for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
		if (value % divisor == 0) return false;
	}
	return true;
}

fn long es_class_for_prime(long prime, long direction) {
	long remainder = prime + direction;
	long result = 1;
	for (long divisor = 2; divisor <= remainder / divisor; divisor += 1) {
		if (remainder % divisor != 0) continue;
		if (divisor > 3) {
			long candidate = 1 + es_class_for_prime(divisor, direction);
			if (candidate > result) result = candidate;
		}
		do {
			remainder /= divisor;
		} while (remainder % divisor == 0);
	}
	if (remainder > 3) {
		long candidate = 1 + es_class_for_prime(remainder, direction);
		if (candidate > result) result = candidate;
	}
	return result;
}

fn long erdos_selfridge_prime_class(long* input, usz length) @export("erdos_selfridge_prime_class") {
	if (input == null || length < 1 || length > 3) return -1;
	if (length != 2) return -1;
	long prime = input[0];
	long direction = input[1];
	if (prime < 2 || prime > ES_MAX_PRIME || (direction != -1 && direction != 1)) return -1;
	if (!es_is_prime(prime)) return -1;
	return es_class_for_prime(prime, direction);
}

