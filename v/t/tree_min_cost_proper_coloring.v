// Uncompiled bounded minimum-cost proper tree coloring draft.
@[export: 'tree_min_cost_proper_coloring']
pub fn tree_min_cost_proper_coloring(input &i64, length usize) i64 {
    if length<2 || length>1090 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv,kv:=input[0],input[1]
        if nv<1 || nv>64 || kv<1 || kv>16 { return -1 }
        n,k:=int(nv),int(kv)
        if length!=usize(n+1+n*k) { return -1 }
        for v in 1 .. n { if input[1+v]<0 || input[1+v]>=i64(v) { return -1 } }
        mut dp:=[1024]i64{}
        for v in 0 .. n { for color in 0 .. k {
            value:=input[n+1+v*k+color]
            if value<0 || value>1000000 { return -1 }
            dp[16*v+color]=value
        } }
        if n>1 && k==1 { return -2 }
        mut child:=n-1
        for child>0 {
            parent:=int(input[1+child])
            mut least:=i64(64000001)
            mut second:=i64(64000001)
            mut best_color:=0
            for color in 0 .. k {
                value:=dp[16*child+color]
                if value<least { second=least; least=value; best_color=color } else if value<second { second=value }
            }
            for color in 0 .. k { dp[16*parent+color]+=if color==best_color { second } else { least } }
            child--
        }
        mut best:=dp[0]
        for color in 1 .. k { if dp[color]<best { best=dp[color] } }
        return best
    }
}
