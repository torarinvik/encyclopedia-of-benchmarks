fn addScaled(a: *[5000]u16, alen: usize, b: *[5000]u16, blen: usize,
              multiplier: u16, out: *[5000]u16) usize {
    var length = @max(alen, blen);
    var carry: u16 = 0;
    for (0..length) |i| {
        const av: u16 = if (i < alen) a[i] else 0;
        const bv: u16 = if (i < blen) b[i] else 0;
        const value = av + multiplier*bv + carry;
        out[i] = value % 10; carry = value / 10;
    }
    while (carry > 0) { out[length] = carry % 10; length += 1; carry /= 10; }
    return length;
}
export fn problem57(n: i64) i64 {
    if (n > 10000) return -1;
    if (n < 1) return 0;
    var prev_n = [_]u16{0} ** 5000; var prev_d = [_]u16{0} ** 5000;
    var cur_n = [_]u16{0} ** 5000; var cur_d = [_]u16{0} ** 5000;
    prev_n[0]=1;prev_d[0]=1;
    var nlen: usize=1;var dlen: usize=1;var count: i64=0;
    var iteration: i64=0;
    while (iteration<n) : (iteration+=1) {
        const cn=addScaled(&prev_n,nlen,&prev_d,dlen,2,&cur_n);
        const cd=addScaled(&prev_n,nlen,&prev_d,dlen,1,&cur_d);
        if (cn>cd) count+=1;
        for (0..cn) |i| prev_n[i]=cur_n[i];
        for (0..cd) |i| prev_d[i]=cur_d[i];
        nlen=cn;dlen=cd;
    }
    return count;
}
