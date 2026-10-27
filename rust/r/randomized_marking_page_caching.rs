const MAX_REQUESTS: usize = 32;
const MAX_PAGES: usize = 16;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT_BYTES: usize = 536;

#[no_mangle]
pub unsafe extern "C" fn randomized_marking_page_caching(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let cache_raw = *input;
    let requests_raw = *input.add(1);
    if cache_raw < 1 || cache_raw > 8 || requests_raw < 0 || requests_raw > MAX_REQUESTS as i64 { return -1; }
    let cache_size = cache_raw as usize;
    let requests = requests_raw as usize;
    if length < 3 + requests { return -1; }
    let choices_raw = *input.add(2 + requests);
    if choices_raw < 0 || choices_raw > requests_raw || length != 3 + requests + choices_raw as usize { return -1; }
    let choice_count = choices_raw as usize;
    let mut pages = [0usize; MAX_REQUESTS];
    let mut choices = [0usize; MAX_REQUESTS];
    for i in 0..requests {
        let page = *input.add(2 + i);
        if page < 0 || page >= MAX_PAGES as i64 { return -1; }
        pages[i] = page as usize;
    }
    for i in 0..choice_count {
        let choice = *input.add(3 + requests + i);
        if choice < 0 || choice > MAX_PAGES as i64 { return -1; }
        choices[i] = choice as usize;
    }

    let mut resident = [false; MAX_PAGES];
    let mut marked = [false; MAX_PAGES];
    let mut hits = [0i64; MAX_REQUESTS];
    let mut victims = [-1i64; MAX_REQUESTS];
    let mut resident_count = 0usize;
    let mut choice_at = 0usize;
    let mut misses = 0i64;
    for request in 0..requests {
        let page = pages[request];
        if resident[page] { hits[request] = 1; marked[page] = true; continue; }
        misses += 1;
        if resident_count == cache_size {
            let mut eligible = [0usize; MAX_PAGES];
            let mut eligible_count = 0usize;
            for candidate in 0..MAX_PAGES {
                if resident[candidate] && !marked[candidate] {
                    eligible[eligible_count] = candidate; eligible_count += 1;
                }
            }
            if eligible_count == 0 {
                for candidate in 0..MAX_PAGES {
                    if resident[candidate] {
                        marked[candidate] = false;
                        eligible[eligible_count] = candidate; eligible_count += 1;
                    }
                }
            }
            if choice_at >= choice_count || choices[choice_at] >= eligible_count { return -1; }
            let victim = eligible[choices[choice_at]];
            choice_at += 1;
            resident[victim] = false; marked[victim] = false; resident_count -= 1;
            victims[request] = victim as i64;
        }
        resident[page] = true; marked[page] = true; resident_count += 1;
    }
    if choice_at != choice_count { return -1; }
    let mut resident_mask = 0i64;
    let mut marked_mask = 0i64;
    for page in 0..MAX_PAGES {
        if resident[page] { resident_mask |= 1i64 << page; }
        if resident[page] && marked[page] { marked_mask |= 1i64 << page; }
    }
    let mut words = [0i64; 3 + 2 * MAX_REQUESTS];
    words[0] = misses; words[1] = resident_mask; words[2] = marked_mask;
    for i in 0..requests { words[3 + i] = hits[i]; words[3 + requests + i] = victims[i]; }
    let output_bytes = 8 * (3 + 2 * requests);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..3 + 2 * requests {
        let bytes = words[word].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), staged.as_mut_ptr().add(8 * word), 8);
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
