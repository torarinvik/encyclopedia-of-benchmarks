fn suffix_less(text &i64, n int, a0 int, b0 int) bool {
    mut a := a0
    mut b := b0
    for a < n && b < n {
        if text[a] != text[b] { return text[a] < text[b] }
        a++
        b++
    }
    return a == n && b != n
}

fn lcp(text &i64, n int, source i64, target int) int {
    if source < 0 { return 0 }
    mut length := 0
    p := int(source)
    for target+length < n && text[p+length] == text[target+length] { length++ }
    return length
}

fn put64(output &u8, at int, value i64) {
    bits := u64(value)
    for i in 0 .. 8 { output[at+i] = u8((bits >> (8*i)) & 255) }
}

@[export: 'lz77_lpf_suffix_array']
pub fn lz77_lpf_suffix_array(input &i64, len usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || len < 1 || len > 34 { return -1 }
        if input[0] < 0 || input[0] > 32 { return -1 }
        n := int(input[0])
        if len != usize(n+1) { return -1 }
        mut text := []i64{len: n, init: 0}
        for i in 0 .. n {
            if input[i+1] < 0 || input[i+1] > 255 { return -1 }
            text[i] = input[i+1]
        }
        mut sa := []int{len: n, init: 0}
        mut inverse := []int{len: n, init: 0}
        mut stack := []int{len: n, init: 0}
        mut previous := []int{len: n, init: -1}
        mut following := []int{len: n, init: -1}
        for i in 0 .. n { sa[i] = i }
        for i in 1 .. n {
            value := sa[i]
            mut j := i
            for j > 0 && suffix_less(&text[0], n, value, sa[j-1]) { sa[j]=sa[j-1]; j-- }
            sa[j] = value
        }
        for rank in 0 .. n { inverse[sa[rank]] = rank }
        mut top := 0
        for rank in 0 .. n {
            for top > 0 && sa[stack[top-1]] > sa[rank] { top-- }
            if top > 0 { previous[rank] = stack[top-1] }
            stack[top] = rank
            top++
        }
        top = 0
        for rr := n; rr > 0; rr-- {
            r := rr-1
            for top > 0 && sa[stack[top-1]] > sa[r] { top-- }
            if top > 0 { following[r] = stack[top-1] }
            stack[top] = r
            top++
        }
        mut staged := []u8{len: 512, init: 0}
        mut pairs := 0
        mut pos := 0
        for pos < n {
            rank := inverse[pos]
            psv := if previous[rank] >= 0 { i64(sa[previous[rank]]) } else { i64(-1) }
            nsv := if following[rank] >= 0 { i64(sa[following[rank]]) } else { i64(-1) }
            lp := lcp(&text[0], n, psv, pos)
            ln := lcp(&text[0], n, nsv, pos)
            mut source := psv
            matched := lp
            if ln > lp { source=nsv; matched=ln }
            if matched == 0 { source = -1 }
            put64(&staged[0], pairs*16, source)
            put64(&staged[0], pairs*16+8, i64(matched))
            pairs++
            pos += if matched > 0 { matched } else { 1 }
        }
        bytes := pairs*16
        if output == nil || capacity < usize(bytes) { return -2 }
        for i in 0 .. bytes { output[i] = staged[i] }
        return i64(bytes)
    }
}
