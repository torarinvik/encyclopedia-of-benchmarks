module key_finder

const max_text_length = i64(256)
const max_input_length = usize(258)
const word_bank = [
	'I ', 'You ', 'We ', 'They ', 'He ', 'She ', 'It ', ' the ',
	'The ', ' of ', ' is ', 'Is ', ' am ', 'Am ', ' are ', 'Are ',
	' have ', 'Have ', ' has ', 'Has ', ' may ', 'May ', ' be ', 'Be ',
]

fn shift_ascii_letter(code i64, key i64) i64 {
	if code >= 65 && code <= 90 { return 65 + (code - 65 + key) % 26 }
	if code >= 97 && code <= 122 { return 97 + (code - 97 + key) % 26 }
	return code
}

@[export: 'key_finder']
pub fn key_finder(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		text_length_value := input[0]
		if text_length_value < 0 || text_length_value > max_text_length { return -1 }
		text_length := int(text_length_value)
		if int(length) != text_length + 1 { return -1 }
		for index in 0 .. text_length {
			code := input[index + 1]
			if code < 32 || code > 126 || (code >= 48 && code <= 57) { return -1 }
		}

		for key in 0 .. 26 {
			key_value := i64(key)
			for start in 0 .. text_length {
				for phrase in word_bank {
					phrase_length := phrase.len
					if start + phrase_length > text_length { continue }
					mut offset := 0
					for offset < phrase_length {
						if shift_ascii_letter(input[start + offset + 1], key_value) != i64(phrase[offset]) { break }
						offset++
					}
					if offset == phrase_length { return key_value }
				}
			}
		}
		return 0
	}
}
