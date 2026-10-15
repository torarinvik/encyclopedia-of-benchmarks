module count_vowels_consonants

const count_base = i64(4_294_967_296)

@[export: 'count_vowels_consonants']
pub fn count_vowels_consonants(values &i64, length usize) i64 {
	if length > 100_000 { return -1 }
	mut vowels := i64(0)
	mut consonants := i64(0)
	unsafe {
		for index in 0 .. length {
			code := values[index]
			if code < 0 || code > 127 { return -1 }
			if (code >= 65 && code <= 90) || (code >= 97 && code <= 122) {
				letter := code | 32
				if letter == 97 || letter == 101 || letter == 105 || letter == 111 || letter == 117 {
					vowels++
				} else {
					consonants++
				}
			}
		}
	}
	return vowels * count_base + consonants
}
