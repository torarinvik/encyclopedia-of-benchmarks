const SMALL: [&str; 21] = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty",
];
const TENS: [&str; 10] = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
const SCALES: [&str; 4] = ["", "Thousand", "Million", "Billion"];

fn append_text(buffer: &mut [u8; 128], mut position: usize, text: &str) -> usize {
    for byte in text.bytes() {
        buffer[position] = byte;
        position += 1;
    }
    position
}

fn append_word(buffer: &mut [u8; 128], mut position: usize, text: &str) -> usize {
    if position != 0 {
        buffer[position] = b' ';
        position += 1;
    }
    append_text(buffer, position, text)
}

fn append_group(buffer: &mut [u8; 128], mut position: usize, mut value: usize) -> usize {
    if value >= 100 {
        position = append_word(buffer, position, SMALL[value / 100]);
        position = append_word(buffer, position, "Hundred");
        value %= 100;
    }
    if value <= 20 {
        if value != 0 { position = append_word(buffer, position, SMALL[value]); }
    } else if value % 10 == 0 {
        position = append_word(buffer, position, TENS[value / 10]);
    } else {
        position = append_word(buffer, position, TENS[value / 10]);
        position = append_word(buffer, position, SMALL[value % 10]);
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn integer_to_english(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let value = *input;
    if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    let mut buffer = [0u8; 128];
    let mut position = 0;
    if value == 0 {
        position = append_word(&mut buffer, position, "Zero");
    } else if value > 0 {
        let mut groups = [0usize; 4];
        let mut remaining = value as usize;
        let mut count = 0;
        while remaining != 0 {
            groups[count] = remaining % 1000;
            count += 1;
            remaining /= 1000;
        }
        while count > 0 {
            count -= 1;
            if groups[count] != 0 {
                position = append_group(&mut buffer, position, groups[count]);
                if count != 0 { position = append_word(&mut buffer, position, SCALES[count]); }
            }
        }
    }
    if position > output_capacity || (position != 0 && output.is_null()) { return -2; }
    for index in 0..position { *output.add(index) = buffer[index]; }
    position as i64
}
