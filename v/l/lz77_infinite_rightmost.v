fn put64(output &u8, at int, value i64) {
    bits := u64(value)
    for i in 0 .. 8 { output[at+i] = u8((bits >> (8*i)) & 255) }
}

@[export: 'lz77_infinite_rightmost']
pub fn lz77_infinite_rightmost(input &i64, len usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || len < 1 || len > 66 { return -1 }
        n64 := input[0]
        if n64 < 0 || n64 > 64 { return -1 }
        n := int(n64)
        if len != usize(n+1) { return -1 }
        for i in 0 .. n { if input[i+1] < 32 || input[i+1] > 126 { return -1 } }
        mut staged := []u8{len:1536,init:0};mut tokens := 0;mut q := 0
        for q < n {
            mut bl := 0;mut bp := 0;mut found := false
            for p in 0 .. q {
                mut l := 0
                for q+l < n && input[p+l+1] == input[q+l+1] { l++ }
                if l > bl || (l == bl && l > 0 && (!found || p > bp)) { bl=l;bp=p;found=true }
            }
            source_pos := if found { i64(bp) } else { i64(0) }
            np := q+bl;ch := if np < n { input[np+1] } else { i64(0) };at := tokens*24
            put64(&staged[0],at,source_pos);put64(&staged[0],at+8,i64(bl));put64(&staged[0],at+16,ch);tokens++
            q = if ch != 0 { np+1 } else { np }
        }
        bytes := tokens*24
        if output == nil || capacity < usize(bytes) { return -2 }
        for i in 0 .. bytes { output[i] = staged[i] }
        return i64(bytes)
    }
}
