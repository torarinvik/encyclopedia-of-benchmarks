/// Construct the source-compatible shortest common supersequence.
#[no_mangle]
pub unsafe extern "C" fn shortest_common_supersequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 130 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let m_value = values[0];
    let n_value = values[1];
    if !(0..=64).contains(&m_value) || !(0..=64).contains(&n_value) {
        return -1;
    }
    let m = m_value as usize;
    let n = n_value as usize;
    if length != 2 + m + n {
        return -1;
    }
    if values[2..].iter().any(|&value| !(32..=126).contains(&value)) {
        return -1;
    }
    let left = &values[2..2 + m];
    let right = &values[2 + m..];

    let mut lcs = [[0i64; 65]; 65];
    for i in 1..=m {
        for j in 1..=n {
            if left[i - 1] == right[j - 1] {
                lcs[i][j] = lcs[i - 1][j - 1] + 1;
            } else {
                lcs[i][j] = lcs[i - 1][j].max(lcs[i][j - 1]);
            }
        }
    }

    let mut reversed = [0u8; 128];
    let (mut used, mut i, mut j) = (0usize, m, n);
    while i > 0 && j > 0 {
        if left[i - 1] == right[j - 1] {
            reversed[used] = left[i - 1] as u8;
            used += 1;
            i -= 1;
            j -= 1;
        } else if lcs[i - 1][j] > lcs[i][j - 1] {
            reversed[used] = left[i - 1] as u8;
            used += 1;
            i -= 1;
        } else {
            // The pinned implementations choose Y when the LCS values tie.
            reversed[used] = right[j - 1] as u8;
            used += 1;
            j -= 1;
        }
    }
    while i > 0 {
        reversed[used] = left[i - 1] as u8;
        used += 1;
        i -= 1;
    }
    while j > 0 {
        reversed[used] = right[j - 1] as u8;
        used += 1;
        j -= 1;
    }

    if output.is_null() || capacity < used {
        return -2;
    }
    for index in 0..used {
        *output.add(index) = reversed[used - 1 - index];
    }
    used as i64
}
