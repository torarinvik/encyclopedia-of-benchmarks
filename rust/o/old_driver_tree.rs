const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 195;
const MAX_RUNS: usize = 36;

#[derive(Clone, Copy, Default)]
struct Run { left: i64, right: i64, value: i64 }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, left: i64, right: i64, arg: i64, extra: i64 }

fn lower_bound(runs: &[Run; MAX_RUNS], count: usize, point: i64) -> usize {
    let (mut lo, mut hi) = (0, count);
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if runs[mid].left < point { lo = mid + 1; } else { hi = mid; }
    }
    lo
}
fn split_at(runs: &mut [Run; MAX_RUNS], count: &mut usize, point: i64, n: i64) {
    if point <= 0 || point >= n { return; }
    let at = lower_bound(runs, *count, point);
    if at < *count && runs[at].left == point { return; }
    let old = runs[at - 1];
    for i in (at..*count).rev() { runs[i + 1] = runs[i]; }
    runs[at - 1].right = point - 1;
    runs[at] = Run { left: point, right: old.right, value: old.value };
    *count += 1;
}
fn coalesce(runs: &mut [Run; MAX_RUNS], count: &mut usize) {
    let mut write = 0;
    for read in 0..*count {
        if write > 0 && runs[write - 1].right + 1 == runs[read].left && runs[write - 1].value == runs[read].value {
            runs[write - 1].right = runs[read].right;
        } else { runs[write] = runs[read]; write += 1; }
    }
    *count = write;
}
fn modular_power(base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut value = base.rem_euclid(modulus);
    let mut result = 1 % modulus;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * value % modulus; }
        value = value * value % modulus;
        exponent >>= 1;
    }
    result
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn old_driver_tree(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0]; let qv = values[1];
    if !(1..=MAX_N as i64).contains(&nv) || !(0..=MAX_Q as i64).contains(&qv) || length < 2 + nv as usize { return -1; }
    let n = nv as usize; let q = qv as usize;
    let mut initial = [0i64; MAX_N];
    for i in 0..n { initial[i] = values[2 + i]; if !(-1000..=1000).contains(&initial[i]) { return -1; } }
    let mut ops = [Operation::default(); MAX_Q];
    let mut cursor = 2 + n; let mut answer_count = 0;
    for slot in ops.iter_mut().take(q) {
        if cursor >= length { return -1; }
        let kind = values[cursor]; cursor += 1;
        let extra_words = if kind == 3 { 4 } else if (0..=2).contains(&kind) { 3 } else { return -1; };
        if length - cursor < extra_words { return -1; }
        let op = Operation { kind, left: values[cursor], right: values[cursor + 1], arg: values[cursor + 2], extra: if kind == 3 { values[cursor + 3] } else { 0 } };
        cursor += extra_words;
        if op.left < 0 || op.left > op.right || op.right >= nv { return -1; }
        if (kind <= 1 && !(-1000..=1000).contains(&op.arg)) ||
           (kind == 2 && !(1..=(op.right - op.left + 1)).contains(&op.arg)) ||
           (kind == 3 && (!(0..=8).contains(&op.arg) || !(1..=1_000_000_000).contains(&op.extra))) { return -1; }
        if kind >= 2 { answer_count += 1; }
        *slot = op;
    }
    if cursor != length || length > 2 + MAX_N + 5 * MAX_Q { return -1; }
    let required = 8 * answer_count;
    if required > 0 && (output.is_null() || capacity < required) { return -2; }
    let mut runs = [Run::default(); MAX_RUNS]; let mut count = 0;
    for i in 0..n {
        if count > 0 && runs[count - 1].value == initial[i] { runs[count - 1].right = i as i64; }
        else { runs[count] = Run { left: i as i64, right: i as i64, value: initial[i] }; count += 1; }
    }
    let mut written = 0;
    for op in ops.iter().take(q) {
        if op.kind <= 1 {
            split_at(&mut runs, &mut count, op.right + 1, nv);
            split_at(&mut runs, &mut count, op.left, nv);
            let start = lower_bound(&runs, count, op.left);
            let end = lower_bound(&runs, count, op.right + 1);
            if op.kind == 0 {
                let removed = end - start; let old_count = count;
                for i in end..old_count { runs[i - removed] = runs[i]; }
                count = old_count - removed;
                for i in (start..count).rev() { runs[i + 1] = runs[i]; }
                runs[start] = Run { left: op.left, right: op.right, value: op.arg }; count += 1;
            } else { for run in runs.iter_mut().take(end).skip(start) { run.value += op.arg; } }
            coalesce(&mut runs, &mut count);
        } else if op.kind == 2 {
            let mut ordered = [0i64; MAX_N]; let mut used = 0;
            for run in runs.iter().take(count) {
                let lo = run.left.max(op.left); let hi = run.right.min(op.right);
                for _ in lo..=hi {
                    let mut at = used;
                    while at > 0 && ordered[at - 1] > run.value { ordered[at] = ordered[at - 1]; at -= 1; }
                    ordered[at] = run.value; used += 1;
                }
            }
            unsafe { store_le(output, 8 * written, ordered[op.arg as usize - 1]); }
            written += 1;
        } else {
            let mut total = 0;
            for run in runs.iter().take(count) {
                let lo = run.left.max(op.left); let hi = run.right.min(op.right);
                if lo <= hi { total = (total + (hi - lo + 1) * modular_power(run.value, op.arg, op.extra)) % op.extra; }
            }
            unsafe { store_le(output, 8 * written, total); }
            written += 1;
        }
    }
    required as i64
}
