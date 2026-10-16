const MAX_INPUT_LENGTH: usize = 512;
const MAX_OUTPUT_BYTES: usize = 2560;
const MORSE: [&[u8]; 26] = [b".-", b"-...", b"-.-.", b"-..", b".", b"..-.", b"--.", b"....", b"..", b".---", b"-.-", b".-..", b"--", b"-.", b"---", b".--.", b"--.-", b".-.", b"...", b"-", b"..-", b"...-", b".--", b"-..-", b"-.--", b"--.."];
fn letter_index(value: i64) -> Option<usize> {
    if value >= 65 && value <= 90 { Some((value - 65) as usize) }
    else if value >= 97 && value <= 122 { Some((value - 97) as usize) }
    else { None }
}
fn append_word(text: &[i64], start: usize, end: usize, out: &mut [u8; MAX_OUTPUT_BYTES], written: &mut usize) {
    for &value in &text[start..end] {
        if let Some(index) = letter_index(value) { for &symbol in MORSE[index] { out[*written] = symbol; *written += 1; } }
        out[*written] = b' '; *written += 1;
    }
}
fn encode(text: &[i64], out: &mut [u8; MAX_OUTPUT_BYTES]) -> usize {
    let mut end = text.len();
    while end > 0 && text[end-1] == 32 { end -= 1; }
    if end == 0 { return 0; }
    let mut written=0; let mut start=0;
    for pos in 0..=end {
        if pos == end || text[pos] == 32 {
            append_word(text,start,pos,out,&mut written);
            if pos<end { out[written]=b'|'; written+=1; out[written]=b' '; written+=1; }
            start=pos+1;
        }
    }
    while written>0 && out[written-1]==b' ' { written-=1; }
    written
}
#[no_mangle]
pub unsafe extern "C" fn morse_code_converter_encode(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if (input.is_null() && length>0) || length>MAX_INPUT_LENGTH { return -1; }
    let text: &[i64]=if length==0 { &[] } else { std::slice::from_raw_parts(input,length) };
    if text.iter().any(|&x| !(0..=127).contains(&x)) { return -1; }
    let mut scratch=[0u8;MAX_OUTPUT_BYTES];
    let written=encode(text,&mut scratch);
    if output.is_null() || capacity<written { return -2; }
    if written>0 { std::ptr::copy_nonoverlapping(scratch.as_ptr(),output,written); }
    written as i64
}
