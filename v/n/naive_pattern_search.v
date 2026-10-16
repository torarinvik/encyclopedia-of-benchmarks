module naive_pattern_search
@[export: 'naive_pattern_search']
pub fn naive_pattern_search(v &i64, n usize) i64 {
    if n < 2 || n > 512 { return -2 }
    unsafe {
        tn,pn:=v[0],v[1]
        if tn < 0 || tn > 255 || pn < 0 || pn > tn || n != usize(2+tn+pn) { return -2 }
        for i in 0..usize(tn+pn) { if v[2+i] < 0 || v[2+i] > 127 { return -2 } }
        if pn == 0 { return -1 }
        for start in i64(0)..=(tn-pn) {
            mut j:=i64(0)
            for j < pn && v[2+usize(start+j)] == v[2+usize(tn+j)] { j++ }
            if j==pn { return start }
        }
        return -1
    }
}
