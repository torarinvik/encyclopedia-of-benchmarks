const MAX_Q: usize = 32;
const MAX_TAGS: usize = 2 * MAX_Q;
const MAX_INPUT: usize = 1 + 4 * MAX_Q;

#[no_mangle]
pub unsafe extern "C" fn observed_remove_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let qv = input[0];
    if !(0..=MAX_Q as i64).contains(&qv) || length != 1 + qv as usize * 4 { return -1; }
    let q = qv as usize;
    for i in 0..q {
        let op = input[1 + i * 4];
        let replica = input[2 + i * 4];
        let element = input[3 + i * 4];
        let peer = input[4 + i * 4];
        if (0..=2).contains(&op) {
            if !(0..=1).contains(&replica) || !(0..=15).contains(&element) || peer != 0 { return -1; }
        } else if op == 3 || op == 4 {
            if !(0..=1).contains(&replica) || element != 0 || !(0..=1).contains(&peer) { return -1; }
        } else { return -1; }
    }

    let mut used = [false; MAX_TAGS];
    let mut tag_element = [0i64; MAX_TAGS];
    let mut next_sequence = [0usize; 2];
    let mut additions = [[false; MAX_TAGS]; 2];
    let mut removals = [[false; MAX_TAGS]; 2];
    let mut answer = 0i64;
    let mut read_count = 0u32;
    for i in 0..q {
        let op = input[1 + i * 4];
        let replica = input[2 + i * 4] as usize;
        let element = input[3 + i * 4];
        let peer = input[4 + i * 4] as usize;
        let mut result = false;
        if op == 0 {
            let tag = replica * MAX_Q + next_sequence[replica];
            next_sequence[replica] += 1;
            used[tag] = true;
            tag_element[tag] = element;
            additions[replica][tag] = true;
        } else if op == 1 {
            for tag in 0..MAX_TAGS {
                if additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element {
                    removals[replica][tag] = true;
                }
            }
        } else if op == 2 {
            for tag in 0..MAX_TAGS {
                if additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element {
                    result = true;
                }
            }
        } else if op == 3 {
            for tag in 0..MAX_TAGS {
                additions[replica][tag] |= additions[peer][tag];
                removals[replica][tag] |= removals[peer][tag];
            }
        } else {
            result = true;
            for tag in 0..MAX_TAGS {
                if (additions[replica][tag] && !additions[peer][tag]) ||
                    (removals[replica][tag] && !removals[peer][tag]) { result = false; }
            }
        }
        if op == 2 || op == 4 {
            if result { answer |= 1i64 << read_count; }
            read_count += 1;
        }
    }
    answer
}
