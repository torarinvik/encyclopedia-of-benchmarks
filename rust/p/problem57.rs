/// Count sqrt(2) convergents whose numerator has more decimal digits.
const MAX_DIGITS: usize = 5000;

#[no_mangle]
pub extern "C" fn problem57(expansions: i64) -> i64 {
    if expansions > 10_000 {
        return -1;
    }
    if expansions < 1 {
        return 0;
    }
    let mut previous_numerator = [0i64; MAX_DIGITS];
    let mut previous_denominator = [0i64; MAX_DIGITS];
    let mut next_numerator = [0i64; MAX_DIGITS];
    let mut next_denominator = [0i64; MAX_DIGITS];
    previous_numerator[0] = 1;
    previous_denominator[0] = 1;
    let mut numerator_length = 1usize;
    let mut denominator_length = 1usize;
    let mut count = 0i64;

    for _ in 0..expansions {
        let active = numerator_length.max(denominator_length);
        let mut carry = 0i64;
        for position in 0..active {
            let left = if position < numerator_length { previous_numerator[position] } else { 0 };
            let right = if position < denominator_length { previous_denominator[position] } else { 0 };
            let total = left + 2 * right + carry;
            next_numerator[position] = total % 10;
            carry = total / 10;
        }
        let mut next_numerator_length = active;
        while carry != 0 {
            next_numerator[next_numerator_length] = carry % 10;
            next_numerator_length += 1;
            carry /= 10;
        }
        carry = 0;
        for position in 0..active {
            let left = if position < numerator_length { previous_numerator[position] } else { 0 };
            let right = if position < denominator_length { previous_denominator[position] } else { 0 };
            let total = left + right + carry;
            next_denominator[position] = total % 10;
            carry = total / 10;
        }
        let mut next_denominator_length = active;
        while carry != 0 {
            next_denominator[next_denominator_length] = carry % 10;
            next_denominator_length += 1;
            carry /= 10;
        }
        if next_numerator_length > next_denominator_length { count += 1; }
        previous_numerator[..next_numerator_length].copy_from_slice(&next_numerator[..next_numerator_length]);
        previous_denominator[..next_denominator_length].copy_from_slice(&next_denominator[..next_denominator_length]);
        numerator_length = next_numerator_length;
        denominator_length = next_denominator_length;
    }
    count
}
