module hamiltonian_path_exists
const max_states = 256
@[export: 'hamiltonian_path_exists']
pub fn hamiltonian_path_exists(input &i64, length usize) i64 {
    if unsafe { input == nil } { return i64(-1) }
    if length < 1 || length > 65 { return i64(-1) }
    unsafe {
        n_value:=input[0]
        if n_value<0 || n_value>8 { return i64(-1) }
        n:=int(n_value)
        if length!=usize(1+n*n) { return i64(-1) }
        mut routes:=[8]u64{}
        for row in 0..n { for col in 0..n { cell:=input[1+row*n+col]; if cell!=0 && cell!=1 { return i64(-1) }; if cell==1 { routes[row] |= u64(1)<<col } } }
        mut dp:=[]bool{len:max_states*8}
        for start in 0..n { dp[(1<<start)*8+start]=true }
        full:=(1<<n)-1
        for subset in 1..(1<<n) {
            for last in 0..n {
                if !dp[subset*8+last] { continue }
                for next in 0..n { bit:=1<<next; if (subset&bit)==0 && (routes[last]&(u64(1)<<next))!=0 { dp[(subset|bit)*8+next]=true } }
            }
        }
        for last in 0..n { if dp[full*8+last] { return 1 } }
        return 0
    }
}
