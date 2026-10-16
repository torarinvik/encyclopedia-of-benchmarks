const MAX_ROW: i64 = 30;
const MOD: i64 = 1_000_000_007;
#[no_mangle]
pub extern "C" fn pascal_triangle_ii(row: i64) -> i64 {
    if !(0..=MAX_ROW).contains(&row) { return i64::MIN; }
    let mut triangle = [[0i64; 31]; 31];
    triangle[0][0] = 1;
    for i in 1..=row as usize {
        triangle[i][0] = 1; triangle[i][i] = 1;
        for j in 1..i { triangle[i][j] = triangle[i-1][j-1] + triangle[i-1][j]; }
    }
    let mut hash = 0;
    for j in 0..=row as usize { hash = (hash * 31 + triangle[row as usize][j]) % MOD; }
    hash
}
