module perfect_shuffle_order

const max_deck_size = i64(10000)

@[export: 'perfect_shuffle_order']
pub fn perfect_shuffle_order(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		deck_size_value := input[0]
		if deck_size_value < 2 || deck_size_value > max_deck_size || deck_size_value % 2 != 0 {
			return -1
		}

		deck_size := int(deck_size_value)
		mut decks := []u16{len: 2 * deck_size, init: 0}
		for index in 0 .. deck_size {
			decks[index] = u16(index)
		}

		mut current_start := 0
		mut following_start := deck_size
		half := deck_size / 2
		mut shuffle_count := i64(0)
		for {
			for index in 0 .. half {
				decks[following_start + 2 * index] = decks[current_start + index]
				decks[following_start + 2 * index + 1] = decks[current_start + half + index]
			}
			shuffle_count++

			mut restored := true
			for index in 0 .. deck_size {
				if decks[following_start + index] != u16(index) {
					restored = false
					break
				}
			}
			if restored { return shuffle_count }

			temporary := current_start
			current_start = following_start
			following_start = temporary
		}
	}
}
