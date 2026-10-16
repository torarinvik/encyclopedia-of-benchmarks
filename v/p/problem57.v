module problem57

fn add_scaled(a [5000]int, alen int, b [5000]int, blen int, multiplier int, mut out [5000]int) int {
    mut length := if alen > blen { alen } else { blen }
    mut carry := 0
    for i in 0 .. length {
        av := if i < alen { a[i] } else { 0 }
        bv := if i < blen { b[i] } else { 0 }
        value := av + multiplier*bv + carry
        out[i] = value%10; carry = value/10
    }
    for carry > 0 { out[length] = carry%10; length++; carry /= 10 }
    return length
}

@[export: 'problem57']
pub fn problem57(n i64) i64 {
    if n > 10000 { return -1 }
    if n < 1 { return 0 }
    mut prev_n := [5000]int{}; mut prev_d := [5000]int{}
    mut cur_n := [5000]int{}; mut cur_d := [5000]int{}
    prev_n[0]=1;prev_d[0]=1
    mut nlen:=1;mut dlen:=1;mut count:=i64(0)
    for _ in 0 .. int(n) {
        cn:=add_scaled(prev_n,nlen,prev_d,dlen,2,mut cur_n)
        cd:=add_scaled(prev_n,nlen,prev_d,dlen,1,mut cur_d)
        if cn>cd {count++}
        for i in 0 .. cn {prev_n[i]=cur_n[i]}
        for i in 0 .. cd {prev_d[i]=cur_d[i]}
        nlen=cn;dlen=cd
    }
    return count
}
