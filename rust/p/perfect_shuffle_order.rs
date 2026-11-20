const MAX_DECK_SIZE: i64 = 10_000;
const DECK_CAPACITY: usize = 10_000;
const DECK_STORAGE: usize = 2 * DECK_CAPACITY;

#[no_mangle]
pub unsafe extern "C" fn perfect_shuffle_order(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let deck_size_value = *input;
    if !(2..=MAX_DECK_SIZE).contains(&deck_size_value) || deck_size_value % 2 != 0 {
        return -1;
    }

    let deck_size = deck_size_value as usize;
    let mut decks = [0u16; DECK_STORAGE];
    for index in 0..deck_size {
        decks[index] = index as u16;
    }

    let mut current_start = 0usize;
    let mut following_start = DECK_CAPACITY;
    let half = deck_size / 2;
    let mut shuffle_count = 0i64;
    loop {
        for index in 0..half {
            decks[following_start + 2 * index] = decks[current_start + index];
            decks[following_start + 2 * index + 1] =
                decks[current_start + half + index];
        }
        shuffle_count += 1;

        let mut restored = true;
        for index in 0..deck_size {
            if decks[following_start + index] != index as u16 {
                restored = false;
                break;
            }
        }
        if restored {
            return shuffle_count;
        }

        std::mem::swap(&mut current_start, &mut following_start);
    }
}
