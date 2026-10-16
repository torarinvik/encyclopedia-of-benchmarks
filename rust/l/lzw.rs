const MAX_ITEMS: usize = 4096;
const MAX_CODES: usize = 4352;
const MAX_OUTPUT: usize = 65536;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    hash
}

fn hash_record(mode: i64, values: &[i64]) -> i64 {
    let mut hash = hash_i64(FNV_OFFSET, mode);
    hash = hash_i64(hash, values.len() as i64);
    for &value in values { hash = hash_i64(hash, value); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

fn expand_code(code: usize, dictionary_size: usize, prefix: &[i32; MAX_CODES],
               suffix: &[u8; MAX_CODES], phrase: &mut [u8; MAX_CODES]) -> Option<usize> {
    let mut length = 0usize;
    let mut current = code;
    while current >= 256 {
        if current >= dictionary_size || length >= MAX_CODES { return None; }
        phrase[length] = suffix[current];
        length += 1;
        let parent = prefix[current];
        if parent < 0 { return None; }
        current = parent as usize;
    }
    if length >= MAX_CODES { return None; }
    phrase[length] = current as u8;
    length += 1;
    phrase[..length].reverse();
    Some(length)
}

#[no_mangle]
pub extern "C" fn lzw(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_ITEMS + 2 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let mode = a[0];
    let count64 = a[1];
    if (mode != 0 && mode != 1) || count64 < 0 || count64 > MAX_ITEMS as i64 || length != count64 as usize + 2 { return -1; }
    let count = count64 as usize;

    let mut prefix = [-1i32; MAX_CODES];
    let mut next_sibling = [-1i32; MAX_CODES];
    let mut first_child = [-1i32; MAX_CODES];
    let mut suffix = [0u8; MAX_CODES];
    let mut first_symbol = [0u8; MAX_CODES];
    for code in 0..256 { suffix[code] = code as u8; first_symbol[code] = code as u8; }

    if mode == 0 {
        if a[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
        let mut codes = [0i64; MAX_ITEMS];
        let mut code_count = 0usize;
        if count > 0 {
            let mut dictionary_size = 256usize;
            let mut current = a[2] as usize;
            for i in 1..count {
                let byte = a[2 + i] as u8;
                let mut match_code = first_child[current];
                while match_code >= 0 && suffix[match_code as usize] != byte {
                    match_code = next_sibling[match_code as usize];
                }
                if match_code >= 0 {
                    current = match_code as usize;
                } else {
                    codes[code_count] = current as i64;
                    code_count += 1;
                    if dictionary_size >= MAX_CODES { return -1; }
                    prefix[dictionary_size] = current as i32;
                    suffix[dictionary_size] = byte;
                    first_symbol[dictionary_size] = first_symbol[current];
                    next_sibling[dictionary_size] = first_child[current];
                    first_child[current] = dictionary_size as i32;
                    dictionary_size += 1;
                    current = byte as usize;
                }
            }
            codes[code_count] = current as i64;
            code_count += 1;
        }
        return hash_record(0, &codes[..code_count]);
    }

    if a[2..].iter().any(|&value| value < 0 || value >= MAX_CODES as i64) { return -1; }
    if count == 0 { return hash_record(1, &[]); }
    let first_code = a[2] as usize;
    if first_code > 127 { return -1; }
    let mut decoded = [0u8; MAX_OUTPUT];
    let mut phrase = [0u8; MAX_CODES];
    decoded[0] = first_code as u8;
    let mut decoded_length = 1usize;
    let mut dictionary_size = 256usize;
    let mut previous = first_code;

    for &raw_code in &a[3..] {
        let code = raw_code as usize;
        let phrase_length = if code < dictionary_size {
            match expand_code(code, dictionary_size, &prefix, &suffix, &mut phrase) { Some(n) => n, None => return -1 }
        } else if code == dictionary_size {
            let n = match expand_code(previous, dictionary_size, &prefix, &suffix, &mut phrase) { Some(n) => n, None => return -1 };
            if n >= MAX_CODES { return -1; }
            phrase[n] = first_symbol[previous];
            n + 1
        } else { return -1; };

        if decoded_length > MAX_OUTPUT - phrase_length || phrase[..phrase_length].iter().any(|&byte| byte > 127) { return -1; }
        decoded[decoded_length..decoded_length + phrase_length].copy_from_slice(&phrase[..phrase_length]);
        decoded_length += phrase_length;
        if dictionary_size >= MAX_CODES { return -1; }
        let next_byte = if code == dictionary_size { first_symbol[previous] } else { first_symbol[code] };
        prefix[dictionary_size] = previous as i32;
        suffix[dictionary_size] = next_byte;
        first_symbol[dictionary_size] = first_symbol[previous];
        dictionary_size += 1;
        previous = code;
    }
    let mut hash = hash_i64(FNV_OFFSET, 1);
    hash = hash_i64(hash, decoded_length as i64);
    for &byte in &decoded[..decoded_length] { hash = hash_i64(hash, i64::from(byte)); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
