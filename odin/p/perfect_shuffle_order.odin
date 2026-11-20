package perfect_shuffle_order

import "core:c"

MAX_DECK_SIZE :: 10000

@(export)
perfect_shuffle_order :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != c.size_t(1) do return -1
	deck_size_word := input[0]
	if deck_size_word < 2 || deck_size_word > i64(MAX_DECK_SIZE) || deck_size_word % 2 != 0 do return -1
	deck_size := int(deck_size_word)
	half := deck_size / 2

	deck: [MAX_DECK_SIZE]i64 = {}
	following: [MAX_DECK_SIZE]i64 = {}
	for index := 0; index < deck_size; index += 1 {
		deck[index] = i64(index)
	}

	repetitions: i64 = 0
	for {
		for index := 0; index < half; index += 1 {
			following[index * 2] = deck[index]
			following[index * 2 + 1] = deck[half + index]
		}
		repetitions += 1

		restored := true
		for index := 0; index < deck_size; index += 1 {
			if following[index] != i64(index) {
				restored = false
				break
			}
		}
		if restored do return repetitions

		for index := 0; index < deck_size; index += 1 {
			deck[index] = following[index]
		}
	}
}
