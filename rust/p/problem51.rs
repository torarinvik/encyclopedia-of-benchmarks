const PRIME_LIMIT: usize = 1_000_000;
const PRIME: u8 = 1;
const FILTERED_PRIME: u8 = 2;
const FILTERED_CHECKED: u8 = 3;
const CHECKED_NONPRIME: u8 = 4;
const CHECKED_OTHER_PRIME: u8 = 5;

fn repeated_extra_digits(value: i64) -> usize {
    let mut counts = [0usize; 10];
    let mut length = 0usize;
    let mut remaining = value;
    while remaining > 0 {
        counts[(remaining % 10) as usize] += 1;
        length += 1;
        remaining /= 10;
    }
    length - counts.iter().filter(|&&count| count > 0).count()
}

fn count_digit(value: i64, digit: i64) -> usize {
    let mut count = 0usize;
    let mut remaining = value;
    while remaining > 0 {
        if remaining % 10 == digit { count += 1; }
        remaining /= 10;
    }
    count
}

fn replace_all(value: i64, digit: i64, replacement: i64) -> i64 {
    let mut result = value;
    let mut remaining = value;
    let mut place = 1i64;
    while remaining > 0 {
        if remaining % 10 == digit { result += (replacement - digit) * place; }
        remaining /= 10;
        place *= 10;
    }
    result
}

fn mark_checked(state: &mut [u8], value: i64) {
    let index = value as usize;
    if state[index] == FILTERED_PRIME { state[index] = FILTERED_CHECKED; }
    else if state[index] == 0 { state[index] = CHECKED_NONPRIME; }
    else if state[index] == PRIME { state[index] = CHECKED_OTHER_PRIME; }
}

#[no_mangle]
pub extern "C" fn problem51(ignored: i64) -> i64 {
    if ignored != 0 { return -1; }
    let mut state = [0u8; PRIME_LIMIT];
    state[2..].fill(PRIME);
    for prime in 2..PRIME_LIMIT {
        if prime * prime >= PRIME_LIMIT { break; }
        if state[prime] != PRIME { continue; }
        for multiple in (prime * prime..PRIME_LIMIT).step_by(prime) { state[multiple] = 0; }
    }
    for value in 2..PRIME_LIMIT {
        if state[value] == PRIME && repeated_extra_digits(value as i64) >= 3 {
            state[value] = FILTERED_PRIME;
        }
    }
    for number in 2..PRIME_LIMIT {
        if state[number] != FILTERED_PRIME { continue; }
        let value = number as i64;
        let mut place = 1i64;
        while value / place >= 10 { place *= 10; }
        let mut seen_digits = [false; 10];
        while place > 0 {
            let digit = (value / place % 10) as usize;
            if !seen_digits[digit] && count_digit(value, digit as i64) >= 2 {
                seen_digits[digit] = true;
                let mut family_count = 0usize;
                let mut family_minimum = i64::MAX;
                for replacement in 0..=9i64 {
                    let member = replace_all(value, digit as i64, replacement);
                    mark_checked(&mut state, member);
                    let member_state = state[member as usize];
                    if member_state == FILTERED_PRIME || member_state == FILTERED_CHECKED {
                        family_count += 1;
                        family_minimum = family_minimum.min(member);
                    }
                }
                if family_count == 8 { return family_minimum; }
            }
            place /= 10;
        }
    }
    -1
}
