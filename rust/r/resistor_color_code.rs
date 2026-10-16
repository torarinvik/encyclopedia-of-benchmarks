use std::slice;

const MAX_TEXT_LENGTH: i64 = 41;
const MAX_PARSEABLE_LENGTH: usize = 43;
const COLOR_NAMES: [&str; 12] = [
    "Black", "Brown", "Red", "Orange", "Yellow", "Green",
    "Blue", "Violet", "Grey", "White", "Gold", "Silver",
];
const TOLERANCE_TEXT: [&str; 12] = ["", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"];
const TEMPERATURE_VALUES: [u64; 9] = [250, 100, 50, 15, 25, 20, 10, 5, 1];

fn color_code(values: &[i64], start: usize, end: usize) -> Option<usize> {
    COLOR_NAMES.iter().position(|name| {
        name.len() == end - start
            && name.bytes().enumerate().all(|(i, byte)| values[start + i + 1] == i64::from(byte))
    })
}

fn append_hundredths(output: &mut String, value: u64) {
    let whole = value / 100;
    let fraction = value % 100;
    output.push_str(&whole.to_string());
    output.push('.');
    if fraction == 0 { output.push('0'); }
    else if fraction % 10 == 0 { output.push(char::from(b'0' + (fraction / 10) as u8)); }
    else {
        output.push(char::from(b'0' + (fraction / 10) as u8));
        output.push(char::from(b'0' + (fraction % 10) as u8));
    }
}

#[no_mangle]
pub unsafe extern "C" fn resistor_color_code(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let input = slice::from_raw_parts(values, length);
    let text_length = input[0];
    if !(1..=MAX_TEXT_LENGTH).contains(&text_length) || length != text_length as usize + 1 { return -1; }
    if input[1..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }

    let mut colors = [0usize; 6];
    let mut color_count = 0usize;
    let mut start = 0usize;
    for i in 0..=text_length as usize {
        if i == text_length as usize || input[i + 1] == i64::from(b',') {
            if color_count == colors.len() || i == start { return -1; }
            let Some(color) = color_code(input, start, i) else { return -1; };
            colors[color_count] = color;
            color_count += 1;
            start = i + 1;
        }
    }
    if !(3..=6).contains(&color_count) { return -1; }

    let significant_count = if color_count <= 4 { 2 } else { 3 };
    let mut significant = 0u64;
    for &color in &colors[..significant_count] {
        if color > 9 { return -1; }
        significant = significant * 10 + color as u64;
    }
    let multiplier = colors[significant_count];
    let tolerance_color = if color_count >= 4 { Some(colors[significant_count + 1]) } else { None };
    let temperature_color = if color_count == 6 { Some(colors[5]) } else { None };
    if tolerance_color.is_some_and(|color| !((1..=8).contains(&color) || color == 10 || color == 11)) { return -1; }
    if temperature_color.is_some_and(|color| color > 8) { return -1; }

    let mut answer = String::new();
    if multiplier <= 9 {
        let resistance = significant * 10u64.pow(multiplier as u32);
        answer.push_str(&resistance.to_string());
    } else if multiplier == 10 {
        answer.push_str(&(significant / 10).to_string());
        answer.push('.');
        answer.push(char::from(b'0' + (significant % 10) as u8));
    } else {
        append_hundredths(&mut answer, significant);
    }
    answer.push_str("\u{03a9} \u{00b1}");
    answer.push_str(match tolerance_color { Some(color) => TOLERANCE_TEXT[color], None => "20" });
    answer.push_str("% ");
    if let Some(color) = temperature_color {
        answer.push_str(&TEMPERATURE_VALUES[color].to_string());
        answer.push_str(" ppm/K");
    }

    if answer.len() > capacity || (output.is_null() && !answer.is_empty()) { return -2; }
    std::ptr::copy_nonoverlapping(answer.as_ptr(), output, answer.len());
    answer.len() as i64
}
