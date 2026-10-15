/// Find the greatest h for which at least h citations are >= h.
#[no_mangle]
pub extern "C" fn h_index(citations: *const i64, length: usize) -> i64 {
    if length > 5000 { return -1; }
    if length == 0 { return 0; }
    let citations = unsafe { std::slice::from_raw_parts(citations, length) };
    if citations.iter().any(|&value| !(0..=1000).contains(&value)) { return -1; }

    let mut low = 0usize;
    let mut high = length.min(1000);
    while low < high {
        let middle = low + (high - low + 1) / 2;
        let mut qualifying = 0usize;
        for &value in citations {
            if value as usize >= middle {
                qualifying += 1;
                if qualifying >= middle { break; }
            }
        }
        if qualifying >= middle { low = middle; }
        else { high = middle - 1; }
    }
    low as i64
}
