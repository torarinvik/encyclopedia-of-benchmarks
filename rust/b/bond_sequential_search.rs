const MAX_N: usize = 64;
const MAX_VALUE: i64 = 255;
const ABSENT_CODE: i64 = 64;
const PACK_BASE: i64 = 65;

#[no_mangle]
pub unsafe extern "C" fn bond_sequential_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_N + 4 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    let key_a = values[1];
    let key_b = values[2];
    if count_value < 0 || count_value > MAX_N as i64 || length != count_value as usize + 3
        || !(0..=MAX_VALUE).contains(&key_a) || !(0..=MAX_VALUE).contains(&key_b)
        || key_a == key_b
    {
        return -1;
    }
    let items = &values[3..];
    if items.iter().any(|&value| !(0..=MAX_VALUE).contains(&value)) {
        return -1;
    }

    let mut index_a = ABSENT_CODE;
    let mut index_b = ABSENT_CODE;
    let composite = key_a | key_b;
    for (index, &value) in items.iter().enumerate() {
        if index_a != ABSENT_CODE && index_b != ABSENT_CODE {
            break;
        }
        if value & composite != value {
            continue;
        }
        if index_a == ABSENT_CODE && value == key_a {
            index_a = index as i64;
        }
        if index_b == ABSENT_CODE && value == key_b {
            index_b = index as i64;
        }
    }
    index_a * PACK_BASE + index_b
}
