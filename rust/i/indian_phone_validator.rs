fn is_ascii_whitespace(value: i64) -> bool {
    matches!(value, 9 | 10 | 11 | 12 | 13 | 32)
}

fn mobile_tail(phone: &[i64], ending: usize, position: usize) -> bool {
    if position > ending || ending - position != 10 {
        return false;
    }
    if !(55..=57).contains(&phone[position]) {
        return false;
    }
    phone[position + 1..ending]
        .iter()
        .all(|&digit| (48..=57).contains(&digit))
}

#[no_mangle]
pub unsafe extern "C" fn indian_phone_validator(phone: *const i64, length: usize) -> i64 {
    if phone.is_null() || length == 0 || length > 18 {
        return -1;
    }
    let phone = std::slice::from_raw_parts(phone, length);
    if phone.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut ending = length;
    if phone[ending - 1] == 10 {
        ending -= 1;
    }
    let mut prefix = 0;
    if ending >= 3 && phone[0] == 43 && phone[1] == 57 && phone[2] == 49 {
        prefix = 3;
        if prefix < ending && (phone[prefix] == 45 || is_ascii_whitespace(phone[prefix])) {
            prefix += 1;
        }
    }

    for zero in 0..=1 {
        let mut after_zero = prefix;
        if zero == 1 {
            if after_zero >= ending || phone[after_zero] != 48 {
                continue;
            }
            after_zero += 1;
        }
        for country in 0..=1 {
            let mut position = after_zero;
            if country == 1 {
                if position + 2 > ending || phone[position] != 57 || phone[position + 1] != 49 {
                    continue;
                }
                position += 2;
            }
            if mobile_tail(phone, ending, position) {
                return 1;
            }
        }
    }
    0
}
