package problem57

add_scaled :: proc(a: ^[5000]int, alen: int, b: ^[5000]int, blen: int, multiplier: int, out: ^[5000]int) -> int {
    length := max(alen, blen); carry := 0
    for i := 0; i < length; i += 1 {
        av := 0; bv := 0
        if i < alen do av = a[i]
        if i < blen do bv = b[i]
        value := av + multiplier*bv + carry
        out[i] = value%10; carry = value/10
    }
    for carry > 0 { out[length] = carry%10; length += 1; carry /= 10 }
    return length
}

@(export)
problem57 :: proc "c" (n: i64) -> i64 {
    if n > 10000 do return -1
    if n < 1 do return 0
    prev_n, prev_d, cur_n, cur_d: [5000]int
    prev_n[0] = 1; prev_d[0] = 1
    nlen, dlen := 1, 1
    count := i64(0)
    for iteration := i64(0); iteration < n; iteration += 1 {
        cn := add_scaled(&prev_n,nlen,&prev_d,dlen,2,&cur_n)
        cd := add_scaled(&prev_n,nlen,&prev_d,dlen,1,&cur_d)
        if cn > cd do count += 1
        for i := 0; i < cn; i += 1 { prev_n[i] = cur_n[i] }
        for i := 0; i < cd; i += 1 { prev_d[i] = cur_d[i] }
        nlen = cn; dlen = cd
    }
    return count
}
