// Independently authored draft; not compiled or run.
module circle_line_intersection_symbolic

@[export: 'circle_line_intersection_symbolic']
pub fn circle_line_intersection_symbolic(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length != 6 { return -1 }
        for i in 0 .. 6 { if input[i] < -1000 || input[i] > 1000 { return -1 } }
        x,y,r := input[0],input[1],input[2]
        a,b,c := input[3],input[4],input[5]
        if r < 1 || (a == 0 && b == 0) { return -1 }
        d := a*a+b*b; q := a*x+b*y+c; h := r*r*d-q*q
        k := if h < 0 { i64(0) } else if h == 0 { i64(1) } else { i64(2) }
        words := [k,x*d-a*q,y*d-b*q,d,-b,a,h]!
        count := if h < 0 { 1 } else { 7 }
        needed := 8*count
        if output == nil || capacity < usize(needed) { return -2 }
        for i in 0 .. count {
            bits := u64(words[i])
            for j in 0 .. 8 { output[8*i+j] = u8((bits >> (8*j)) & 255) }
        }
        return i64(needed)
    }
}
