module is_pangram

@[export: 'is_pangram']
pub fn is_pangram(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    mut seen := [26]bool{}
    mut found := 0
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < 0 || value > 127 { return -1 }
        letter_value := if value >= 65 && value <= 90 { value + 32 } else { value }
        if letter_value >= 97 && letter_value <= 122 {
            letter := int(letter_value - 97)
            if !seen[letter] {
                seen[letter] = true
                found++
            }
        }
    }
    return if found == 26 { 1 } else { 0 }
}
