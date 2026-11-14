// Uncompiled and unexecuted weighted-binary-search draft.
fn evaluate(weights: &[i64], penalty: i64) -> (i64, i64) {
    let (mut two, mut one) = ((0, 0), (0, 0));
    for &weight in weights {
        let take = (two.0+weight-penalty, two.1+1);
        let current = one.max(take);
        two = one; one = current;
    }
    one
}
#[no_mangle]
pub unsafe extern "C" fn wqs_path_independent_set(input: *const i64, length: usize) -> i64 {
    const INVALID: i64 = -1_000_000_000;
    if input.is_null() || !(2..=130).contains(&length) { return INVALID; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) || values[1] < 0 || values[1] > (values[0]+1)/2 { return INVALID; }
    let n = values[0] as usize;
    if length != n+2 || values[2..].iter().any(|&x| !(-1000..=1000).contains(&x)) { return INVALID; }
    let (mut low, mut high) = (-256001i64, 256001i64);
    while low < high {
        let middle = low+(high-low+1)/2;
        if evaluate(&values[2..], middle).1 >= values[1] { low = middle; } else { high = middle-1; }
    }
    evaluate(&values[2..], low).0+low*values[1]
}
