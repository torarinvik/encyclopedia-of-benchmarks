/// Proposer-proposing Gale-Shapley stable matching for complete preferences.
#[no_mangle]
pub extern "C" fn gale_shapley(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 66 {
        return -2;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=5).contains(&values[0]) {
        return -2;
    }
    let count = values[0] as usize;
    if length != 1 + 2 * count * count {
        return -2;
    }
    let mut ranks = [[0_i64; 5]; 5];
    let mut seen = [false; 5];
    for proposer in 0..count {
        seen.fill(false);
        for rank in 0..count {
            let accepter = values[1 + proposer * count + rank];
            if !(0..count as i64).contains(&accepter) || seen[accepter as usize] {
                return -2;
            }
            seen[accepter as usize] = true;
        }
    }
    let accepter_offset = 1 + count * count;
    for accepter in 0..count {
        seen.fill(false);
        for rank in 0..count {
            let proposer = values[accepter_offset + accepter * count + rank];
            if !(0..count as i64).contains(&proposer) || seen[proposer as usize] {
                return -2;
            }
            seen[proposer as usize] = true;
            ranks[accepter][proposer as usize] = rank as i64;
        }
    }
    if output_capacity < count || (count != 0 && output.is_null()) {
        return -2;
    }

    let mut matched_proposer = [-1_i64; 5];
    let mut matched_accepter = [-1_i64; 5];
    let mut next_choice = [0_usize; 5];
    loop {
        let mut proposer = 0;
        while proposer < count && matched_accepter[proposer] != -1 {
            proposer += 1;
        }
        if proposer == count {
            break;
        }
        let accepter = values[1 + proposer * count + next_choice[proposer]] as usize;
        next_choice[proposer] += 1;
        let current = matched_proposer[accepter];
        if current == -1 || ranks[accepter][proposer] < ranks[accepter][current as usize] {
            if current != -1 {
                matched_accepter[current as usize] = -1;
            }
            matched_proposer[accepter] = proposer as i64;
            matched_accepter[proposer] = accepter as i64;
        }
    }
    for proposer in 0..count {
        unsafe { *output.add(proposer) = matched_accepter[proposer] as u8; }
    }
    count as i64
}
