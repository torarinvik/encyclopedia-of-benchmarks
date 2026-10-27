const MAX_N: usize = 16;
const MAX_INPUT: usize = 65;

#[no_mangle]
pub unsafe extern "C" fn randomized_rounding_bernoulli(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 1 || n64 > MAX_N as i64 || length != 1 + 4*n64 as usize { return -1; }
    let n = n64 as usize;
    let mut staged = [0u8; MAX_N];
    for i in 0..n {
        let x_num=*input.add(1+4*i); let x_den=*input.add(2+4*i);
        let u_num=*input.add(3+4*i); let u_den=*input.add(4+4*i);
        if x_den<1 || x_den>32 || x_num<0 || x_num>x_den ||
           u_den<1 || u_den>32 || u_num<0 || u_num>=u_den { return -1; }
        staged[i] = u8::from(u_num*x_den < x_num*u_den);
    }
    if output.is_null() || capacity < n { return -2; }
    for i in 0..n { *output.add(i)=staged[i]; }
    n as i64
}
