/// Replay the bounded Clock Patience pile chain.
#[no_mangle]
pub extern "C" fn clock_patience_simulation(values: *const i64, length: usize) -> i64 {
    const PILES: usize = 13;
    const PER_PILE: usize = 4;
    const CARDS: usize = PILES * PER_PILE;
    if values.is_null() || length != CARDS {
        return -1;
    }
    // The caller provides the declared i64-array frame at this C ABI boundary.
    let cards = unsafe { std::slice::from_raw_parts(values, length) };
    let mut rank_counts = [0_u8; PILES + 1];
    for &rank in cards {
        if !(1..=PILES as i64).contains(&rank) {
            return -1;
        }
        rank_counts[rank as usize] += 1;
    }
    if rank_counts[1..].iter().any(|&count| count != PER_PILE as u8) {
        return -1;
    }

    let mut next_card = [0_usize; PILES];
    let mut pile = PILES - 1;
    let mut revealed = 0;
    while next_card[pile] < PER_PILE {
        let rank = cards[pile * PER_PILE + next_card[pile]];
        next_card[pile] += 1;
        revealed += 1;
        pile = (rank - 1) as usize;
    }
    if revealed == CARDS { 1 } else { 0 }
}
