fn suffixLess(s: *const [33]i64, n: usize, a0: usize, b0: usize) bool {
    var a = a0;
    var b = b0;
    while (a < n and b < n) {
        if (s[a] != s[b]) return s[a] < s[b];
        a += 1;
        b += 1;
    }
    return a == n and b != n;
}

export fn fm_index_count(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 4 or length > 42) return -1;
    const n0 = input[0];
    if (n0 < 1 or n0 > 32 or length < @as(usize, @intCast(n0)) + 3) return -1;
    const n: usize = @intCast(n0);
    const m_at = n + 1;
    const m0 = input[m_at];
    if (m0 < 1 or m0 > 8 or length != n + @as(usize, @intCast(m0)) + 2) return -1;
    const m: usize = @intCast(m0);
    const total = n + 1;
    var s: [33]i64 = [_]i64{0} ** 33;
    var pattern: [8]i64 = undefined;
    for (0..n) |i| { const x=input[1+i]; if(x<1 or x>4)return -1; s[i]=x; }
    for (0..m) |i| { const x=input[m_at+1+i]; if(x<1 or x>4)return -1; pattern[i]=x; }
    s[n]=0;
    if (output_capacity < 8) return -2;
    var sa: [33]usize = undefined;
    for (0..total) |i| sa[i]=i;
    for (1..total) |i| {
        const key=sa[i]; var j=i;
        while(j>0 and suffixLess(&s,total,key,sa[j-1])){sa[j]=sa[j-1];j-=1;}
        sa[j]=key;
    }
    var bwt: [33]i64 = undefined; var freq=[_]usize{0}**5;
    for(0..total)|i|{bwt[i]=s[(sa[i]+total-1)%total];freq[@intCast(bwt[i])]+=1;}
    var cumulative=[_]usize{0}**5;var sum:usize=0;
    for(0..5)|x|{cumulative[x]=sum;sum+=freq[x];}
    var left:usize=0;var right=total;
    var k=m;
    while(k>0){k-=1;const symbol:usize=@intCast(pattern[k]);var rl:usize=0;var rr:usize=0;
        for(0..left)|i|{if(bwt[i]==@as(i64,@intCast(symbol)))rl+=1;}
        for(0..right)|i|{if(bwt[i]==@as(i64,@intCast(symbol)))rr+=1;}
        left=cumulative[symbol]+rl;right=cumulative[symbol]+rr;if(left==right)break;
    }
    const count: u64=@intCast(right-left);
    for(0..8)|i|output[i]=@truncate(count>>(8*i));
    return 8;
}
