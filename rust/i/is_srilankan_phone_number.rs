#[no_mangle]
pub unsafe extern "C" fn is_srilankan_phone_number(phone: *const i64, length: usize) -> i64 {
    if phone.is_null() || length == 0 || length > 15 {
        return -1;
    }
    let phone = std::slice::from_raw_parts(phone, length);
    if phone.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let prefix_length = if phone[0] == 48 {
        if length >= 4 && phone[1] == 48 && phone[2] == 57 && phone[3] == 52 {
            4
        } else {
            1
        }
    } else if length >= 2 && phone[0] == 57 && phone[1] == 52 {
        2
    } else if length >= 3 && phone[0] == 43 && phone[1] == 57 && phone[2] == 52 {
        3
    } else {
        return 0;
    };

    let mut cursor = prefix_length;
    if cursor + 2 > length || phone[cursor] != 55 {
        return 0;
    }
    cursor += 1;
    let provider = phone[cursor];
    cursor += 1;
    if ![48, 49, 50, 52, 53, 54, 55, 56].contains(&provider) {
        return 0;
    }

    let mut end = length;
    if phone[end - 1] == 10 {
        end -= 1;
    }
    let remaining = end - cursor;
    if remaining == 8 && (phone[cursor] == 45 || phone[cursor] == 32) {
        cursor += 1;
    } else if remaining != 7 {
        return 0;
    }
    if phone[cursor..cursor + 7]
        .iter()
        .any(|&digit| !(48..=57).contains(&digit))
    {
        return 0;
    }
    1
}
