@[export: 'randomized_rounding_bernoulli']
pub fn randomized_rounding_bernoulli(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 5 || length > 65 { return -1 }
        n64 := input[0]
        if n64 < 1 || n64 > 16 || length != usize(1+4*n64) { return -1 }
        n := int(n64)
        mut staged := []u8{len:n, init:0}
        for i in 0..n {
            x_num:=input[1+4*i]; x_den:=input[2+4*i]
            u_num:=input[3+4*i]; u_den:=input[4+4*i]
            if x_den<1 || x_den>32 || x_num<0 || x_num>x_den ||
               u_den<1 || u_den>32 || u_num<0 || u_num>=u_den { return -1 }
            if u_num*x_den < x_num*u_den { staged[i]=1 } else { staged[i]=0 }
        }
        if output==nil || capacity<usize(n) { return -2 }
        for i in 0..n { output[i]=staged[i] }
        return i64(n)
    }
}
