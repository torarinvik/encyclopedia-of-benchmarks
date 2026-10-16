#[no_mangle]
pub extern "C" fn longest_repeating_subsequence(p: *const i64, n: usize) -> i64 {
 if p.is_null()||n<1||n>256{return -1;} let p=unsafe{std::slice::from_raw_parts(p,n)}; let size=p[0];
 if !(0..=255).contains(&size)||n!=size as usize+1||p[1..].iter().any(|&x|!(0..=127).contains(&x)){return -1;}
 let mut dp=[0i64;256];for i in 1..=size as usize{let mut diag=0;for j in 1..=size as usize{let above=dp[j];if p[i]==p[j]&&i!=j{dp[j]=diag+1;}else if dp[j-1]>dp[j]{dp[j]=dp[j-1];}diag=above;}}dp[size as usize]
}
