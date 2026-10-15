/// Encode ASCII letters and digits as space-separated International Morse.
fn morse_letter_index(value: i64) -> i64 {
    if (65..=90).contains(&value) { return value - 65; }
    if (97..=122).contains(&value) { return value - 97; }
    if (48..=57).contains(&value) { return 26 + value - 48; }
    -1
}

fn morse_word(index: usize) -> i64 {
    if index == 0 { return 514; }
    if index == 1 { return 1031; }
    if index == 2 { return 1029; }
    if index == 3 { return 771; }
    if index == 4 { return 257; }
    if index == 5 { return 1037; }
    if index == 6 { return 769; }
    if index == 7 { return 1039; }
    if index == 8 { return 515; }
    if index == 9 { return 1032; }
    if index == 10 { return 770; }
    if index == 11 { return 1035; }
    if index == 12 { return 512; }
    if index == 13 { return 513; }
    if index == 14 { return 768; }
    if index == 15 { return 1033; }
    if index == 16 { return 1026; }
    if index == 17 { return 773; }
    if index == 18 { return 775; }
    if index == 19 { return 256; }
    if index == 20 { return 774; }
    if index == 21 { return 1038; }
    if index == 22 { return 772; }
    if index == 23 { return 1030; }
    if index == 24 { return 1028; }
    if index == 25 { return 1027; }
    if index == 26 { return 1280; }
    if index == 27 { return 1296; }
    if index == 28 { return 1304; }
    if index == 29 { return 1308; }
    if index == 30 { return 1310; }
    if index == 31 { return 1311; }
    if index == 32 { return 1295; }
    if index == 33 { return 1287; }
    if index == 34 { return 1283; }
    if index == 35 { return 1281; }
    0
}

#[no_mangle]
pub unsafe extern "C" fn morse_code(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if length > 682 { return -1; }
    let mut required = 0usize;
    for index in 0..length {
        let letter = morse_letter_index(*input.add(index));
        if letter < 0 { return -1; }
        let word = morse_word(letter as usize);
        required += ((word >> 8) & 7) as usize;
        if index != 0 { required += 1; }
    }
    if output_capacity < required { return -2; }
    let mut written = 0usize;
    for index in 0..length {
        if index != 0 { *output.add(written) = 32; written += 1; }
        let letter = morse_letter_index(*input.add(index)) as usize;
        let word = morse_word(letter);
        let code_length = ((word >> 8) & 7) as usize;
        let mask = word & 31;
        for position in 0..code_length {
            let shift = code_length - position - 1;
            *output.add(written) = if ((mask >> shift) & 1) != 0 { b'.' } else { b'-' };
            written += 1;
        }
    }
    written as i64
}
