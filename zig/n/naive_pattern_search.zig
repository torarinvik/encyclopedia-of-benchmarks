export fn naive_pattern_search(v: [*]const i64, n: usize) i64 {
    if (n < 2 or n > 512) return -2;
    const tn=v[0]; const pn=v[1];
    if (tn < 0 or tn > 255 or pn < 0 or pn > tn or n != @as(usize,@intCast(2+tn+pn))) return -2;
    for (0..@as(usize,@intCast(tn+pn))) |i| { if (v[2+i] < 0 or v[2+i] > 127) return -2; }
    if (pn == 0) return -1;
    var start: i64=0;
    while (start <= tn-pn) : (start+=1) {
        var j: i64=0;
        while (j < pn and v[@as(usize,@intCast(2+start+j))] == v[@as(usize,@intCast(2+tn+j))]) : (j+=1) {}
        if (j==pn) return start;
    }
    return -1;
}
