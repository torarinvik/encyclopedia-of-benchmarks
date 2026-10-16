const DEAL_COUNT: usize = 1000;
const VALUES_PER_DEAL: usize = 10;

fn rank_hand(cards: &[i64; 5]) -> [i64; 6] {
    let mut ranks = [0i64; 5];
    let mut suits = [0i64; 5];
    let mut counts = [0i64; 15];
    for i in 0..5 {
        ranks[i] = cards[i] / 4 + 2;
        suits[i] = cards[i] % 4;
        counts[ranks[i] as usize] += 1;
    }
    ranks.sort_unstable_by(|a, b| b.cmp(a));
    let mut score = [0i64; 6];
    let flush = suits.iter().all(|suit| *suit == suits[0]);
    let distinct = (2..=14).all(|rank| counts[rank] <= 1);
    let straight_high = if distinct && ranks[0] - ranks[4] == 4 {
        ranks[0]
    } else if distinct && ranks == [14, 5, 4, 3, 2] {
        5
    } else {
        0
    };
    let mut four = 0;
    let mut three = 0;
    let mut pair_high = 0;
    let mut pair_low = 0;
    let mut singles = [0i64; 5];
    let mut single_count = 0usize;
    for rank in (2..=14).rev() {
        match counts[rank] {
            4 => four = rank as i64,
            3 => three = rank as i64,
            2 => {
                if pair_high == 0 { pair_high = rank as i64; }
                else { pair_low = rank as i64; }
            }
            1 => { singles[single_count] = rank as i64; single_count += 1; }
            _ => {}
        }
    }
    if flush && straight_high != 0 {
        score[0] = if straight_high == 14 { 9 } else { 8 };
        score[1] = straight_high;
    } else if four != 0 {
        score[0] = 7; score[1] = four; score[2] = singles[0];
    } else if three != 0 && pair_high != 0 {
        score[0] = 6; score[1] = three; score[2] = pair_high;
    } else if flush {
        score[0] = 5;
        score[1..].copy_from_slice(&ranks);
    } else if straight_high != 0 {
        score[0] = 4; score[1] = straight_high;
    } else if three != 0 {
        score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1];
    } else if pair_low != 0 {
        score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0];
    } else if pair_high != 0 {
        score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2];
    } else {
        score[0] = 0;
        score[1..].copy_from_slice(&ranks);
    }
    score
}

#[no_mangle]
pub unsafe extern "C" fn problem54(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != DEAL_COUNT * VALUES_PER_DEAL { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut wins = 0;
    for deal in 0..DEAL_COUNT {
        let offset = deal * VALUES_PER_DEAL;
        let cards = &values[offset..offset + VALUES_PER_DEAL];
        for i in 0..VALUES_PER_DEAL {
            if !(0..52).contains(&cards[i]) || cards[..i].contains(&cards[i]) { return -1; }
        }
        let first_cards: [i64; 5] = cards[..5].try_into().unwrap();
        let second_cards: [i64; 5] = cards[5..].try_into().unwrap();
        let first = rank_hand(&first_cards);
        let second = rank_hand(&second_cards);
        if first > second { wins += 1; }
    }
    wins
}
