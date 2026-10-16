fn ascii_letter(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}
fn ascii_digit(value: i64) -> bool { (48..=57).contains(&value) }
fn local_special(value: i64) -> bool {
    matches!(value, 33|35|36|37|38|39|40|41|42|43|45|46|47|61|63|94|95|96|123|124|125|126)
}
fn local_allowed(value: i64) -> bool { ascii_letter(value) || ascii_digit(value) || local_special(value) }
fn domain_allowed(value: i64) -> bool { ascii_letter(value) || ascii_digit(value) || value == 46 || value == 45 }

#[no_mangle]
pub unsafe extern "C" fn is_valid_email_address(values: *const i64, length: usize) -> i64 {
    if length > 320 { return 0; }
    if length != 0 && values.is_null() { return -1; }
    let values: &[i64] = if length == 0 { &[] } else { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(0..=0x10ffff).contains(&value)) { return -1; }
    let mut at = length;
    for (index, &value) in values.iter().enumerate() {
        if value == 64 { if at != length { return 0; } at = index; }
    }
    if at == length { return 0; }
    let domain_start = at + 1;
    if at > 64 || length - domain_start > 255 { return 0; }
    for index in 0..at {
        let value = values[index];
        if !local_allowed(value) { return 0; }
        if value == 46 && (index == 0 || index + 1 == at || values[index - 1] == 46) { return 0; }
    }
    for index in domain_start..length {
        let value = values[index];
        if !domain_allowed(value) { return 0; }
        if value == 45 && index == domain_start { return 0; }
        if value == 46 && (index == domain_start || index + 1 == length || values[index - 1] == 46) { return 0; }
    }
    1
}
