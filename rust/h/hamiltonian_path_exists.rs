const MAX_VERTICES: usize = 8;
const MAX_STATES: usize = 256;
const MAX_INPUT_LENGTH: usize = 65;
#[no_mangle]
pub unsafe extern "C" fn hamiltonian_path_exists(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    if *input < 0 || *input > MAX_VERTICES as i64 { return -1; }
    let n=*input as usize;
    if length != 1+n*n { return -1; }
    let mut routes=[0usize;MAX_VERTICES];
    for row in 0..n { for col in 0..n { let cell=*input.add(1+row*n+col); if cell!=0 && cell!=1 { return -1; } if cell==1 { routes[row] |= 1usize<<col; } } }
    let mut dp=[false;MAX_STATES*MAX_VERTICES];
    for start in 0..n { dp[(1usize<<start)*MAX_VERTICES+start]=true; }
    let full=(1usize<<n)-1;
    for subset in 1..(1usize<<n) { for last in 0..n { if !dp[subset*MAX_VERTICES+last] { continue; } for next in 0..n { let bit=1usize<<next; if subset&bit==0 && routes[last]&bit!=0 { dp[(subset|bit)*MAX_VERTICES+next]=true; } } } }
    for last in 0..n { if dp[full*MAX_VERTICES+last] { return 1; } }
    0
}
