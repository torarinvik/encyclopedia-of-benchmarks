const MAX_QUEUES: usize = 4;
const MAX_BUFFER: usize = 4;
const MAX_SLOTS: usize = 8;
const MAX_PARSEABLE_INPUT: usize = 68;
const MAX_OUTPUT_BYTES: usize = 64;

#[derive(Clone, Copy, Default)]
struct Tag { priority: i64, marked: bool }

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn packet_switching_random_schedule(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT { return -1; }
    let m_v = *input;
    let b_v = *input.add(1);
    let t_v = *input.add(2);
    if !(2..=MAX_QUEUES as i64).contains(&m_v) || !(1..=MAX_BUFFER as i64).contains(&b_v) ||
        !(1..=MAX_SLOTS as i64).contains(&t_v) { return -1; }
    let (m, b, t) = (m_v as usize, b_v as usize, t_v as usize);
    let cells = m * t;
    if length != 3 + 2 * cells { return -1; }
    for cell in 0..cells {
        let flag = *input.add(3 + cell);
        let priority = *input.add(3 + cells + cell);
        if !(0..=1).contains(&flag) || !(0..=4_294_967_295).contains(&priority) { return -1; }
    }
    let mut load = [0usize; MAX_QUEUES];
    let mut count = [0usize; MAX_QUEUES];
    let mut tags = [[Tag::default(); MAX_BUFFER]; MAX_QUEUES];
    let mut trace = [-1i64; MAX_SLOTS];
    for slot in 0..t {
        for q in 0..m {
            let cell = slot * m + q;
            if *input.add(3 + cell) == 0 || load[q] == b { continue; }
            if count[q] == b {
                for i in 1..count[q] { tags[q][i - 1] = tags[q][i]; }
                count[q] -= 1;
            }
            tags[q][count[q]] = Tag { priority: *input.add(3 + cells + cell), marked: false };
            count[q] += 1;
            load[q] += 1;
        }
        let mut best: Option<(usize, usize, i64)> = None;
        for q in 0..m { for i in 0..count[q] {
            if tags[q][i].marked { continue; }
            if best.map_or(true, |(best_q, _, score)| tags[q][i].priority > score ||
                tags[q][i].priority == score && q < best_q) { best = Some((q, i, tags[q][i].priority)); }
        }}
        let selected = if let Some((q, i, _)) = best { tags[q][i].marked = true; q }
            else { (0..m).find(|&q| load[q] > 0).unwrap_or(m) };
        if selected < m { trace[slot] = selected as i64; load[selected] -= 1; }
    }
    let bytes = 8 * t;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for slot in 0..t { store_i64_le(staged.as_mut_ptr(), 8 * slot, trace[slot]); }
    for byte in 0..bytes { *output.add(byte) = staged[byte]; }
    bytes as i64
}
