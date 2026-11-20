const MAX_INDEX: i64 = 64;
const MAX_PARSEABLE_LENGTH: usize = 2;

#[no_mangle]
pub unsafe extern "C" fn klarner_rado_affine_closure_sequence(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    let requested = *input;
    if length != 1 || !(1..=MAX_INDEX).contains(&requested) { return -1; }

    let mut terms = [0i64; 64];
    terms[0] = 1;
    let mut count = 1usize;
    let (mut twice, mut thrice_plus_two, mut sixfold_plus_three) = (0usize, 0usize, 0usize);
    while count < requested as usize {
        let by_two = 2 * terms[twice];
        let by_three = 3 * terms[thrice_plus_two] + 2;
        let by_six = 6 * terms[sixfold_plus_three] + 3;
        let next = by_two.min(by_three).min(by_six);
        terms[count] = next;
        count += 1;
        if by_two == next { twice += 1; }
        if by_three == next { thrice_plus_two += 1; }
        if by_six == next { sixfold_plus_three += 1; }
    }
    terms[requested as usize - 1]
}
