const MAX_TEXT: usize = 32;
const MAX_INPUT: usize = 36;
const ALPHABET: usize = 5;

fn suffix_less(text: &[i64; MAX_TEXT + 1], size: usize, a0: usize, b0: usize) -> bool {
    let (mut a, mut b) = (a0, b0);
    while a < size && b < size {
        if text[a] != text[b] { return text[a] < text[b]; }
        a += 1;
        b += 1;
    }
    a == size && b != size
}

#[no_mangle]
pub unsafe extern "C" fn fm_index_display(input: *const i64, length: usize,
                                             output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0];
    if !(1..=MAX_TEXT as i64).contains(&n0) || length != n0 as usize + 4 { return -1; }
    let n = n0 as usize;
    let (left0, right0, stride0) = (words[n + 1], words[n + 2], words[n + 3]);
    if left0 < 0 || right0 < left0 || right0 >= n0 || stride0 < 1 || stride0 > n0 { return -1; }
    let (left, right, stride) = (left0 as usize, right0 as usize, stride0 as usize);
    let size = n + 1;
    let mut text = [0i64; MAX_TEXT + 1];
    for i in 0..n {
        if !(1..=4).contains(&words[i + 1]) { return -1; }
        text[i] = words[i + 1];
    }
    text[n] = 0;
    let mut sa = [0usize; MAX_TEXT + 1];
    for i in 0..size { sa[i] = i; }
    for i in 1..size {
        let key = sa[i];
        let mut j = i;
        while j > 0 && suffix_less(&text, size, key, sa[j - 1]) {
            sa[j] = sa[j - 1];
            j -= 1;
        }
        sa[j] = key;
    }
    let mut isa = [0usize; MAX_TEXT + 1];
    let mut bwt = [0usize; MAX_TEXT + 1];
    let mut freq = [0usize; ALPHABET];
    for row in 0..size {
        let pos = sa[row];
        isa[pos] = row;
        bwt[row] = text[(pos + size - 1) % size] as usize;
        freq[bwt[row]] += 1;
    }
    let mut first = [0usize; ALPHABET];
    let mut sum = 0usize;
    for c in 0..ALPHABET { first[c] = sum; sum += freq[c]; }
    let mut seen = [0usize; ALPHABET];
    let mut lf = [0usize; MAX_TEXT + 1];
    for row in 0..size {
        let symbol = bwt[row];
        lf[row] = first[symbol] + seen[symbol];
        seen[symbol] += 1;
    }
    let mut sampled_isa = [0usize; MAX_TEXT + 1];
    let mut sampled = [false; MAX_TEXT + 1];
    let mut pos = 0;
    while pos < n { if (pos + 1) % stride == 0 { sampled[pos] = true; sampled_isa[pos] = isa[pos]; } pos += 1; }
    sampled[n] = true;
    sampled_isa[n] = isa[n];
    let mut sample = ((right + 1) / stride + 1) * stride - 1;
    if sample > n { sample = n; }
    if !sampled[sample] { return -1; }
    let (mut row, mut current) = (sampled_isa[sample], sample);
    while current > right + 1 { row = lf[row]; current -= 1; }
    let mut reversed = [0u8; MAX_TEXT];
    let mut count = 0usize;
    while current > left { reversed[count] = bwt[row] as u8; count += 1; row = lf[row]; current -= 1; }
    if count != right - left + 1 { return -1; }
    if output.is_null() || capacity < count { return -2; }
    for i in 0..count { *output.add(i) = reversed[count - 1 - i]; }
    count as i64
}
