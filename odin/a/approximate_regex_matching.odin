package approximate_regex_matching

import "core:c"

// Layered edit-distance shortest paths over a supplied literal NFA.
@(export)
approximate_regex_matching :: proc "c" (x: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if x == nil do return -2
    if length < 6 || length > 66 do return -1
    sv, ev, tv, kv, startv, acceptv := x[0],x[1],x[2],x[3],x[4],x[5]
    if sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||startv<0||acceptv<0||startv>=sv||acceptv>=sv||startv==acceptv do return -1
    s,e,t,k,start,accept := int(sv),int(ev),int(tv),int(kv),int(startv),int(acceptv)
    ts := 6+3*e
    if int(length)!=ts+t do return -1
    from: [16]int
    to: [16]int
    label: [16]u8
    for i:=0;i<e;i+=1 {
        u,v,ch:=x[6+3*i],x[7+3*i],x[8+3*i]
        if u<0||u>=sv||v<0||v>=sv||ch<1||ch>127 do return -1
        from[i],to[i],label[i]=int(u),int(v),u8(ch)
        for j:=0;j<i;j+=1 { if from[i]==from[j]&&to[i]==to[j]&&label[i]==label[j] do return -1 }
    }
    for i:=0;i<t;i+=1 { if x[ts+i]<1||x[ts+i]>127 do return -1 }
    if capacity<c.size_t(t)||(t>0&&output==nil) do return -2
    inf:=k+1
    cur,next:[8]int
    for q:=0;q<s;q+=1 {cur[q]=inf}
    for pos:=0;pos<t;pos+=1 {
        cur[start]=0
        for pass:=0;pass<s-1;pass+=1 {
            changed:=false
            for i:=0;i<e;i+=1 {if cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]] {cur[to[i]]=cur[from[i]]+1;changed=true}}
            if !changed do break
        }
        for q:=0;q<s;q+=1 {if cur[q]<inf {next[q]=cur[q]+1} else {next[q]=inf}}
        for i:=0;i<e;i+=1 {if cur[from[i]]<inf {cost:=cur[from[i]];if label[i]!=u8(x[ts+pos]) {cost+=1};if cost<next[to[i]] {next[to[i]]=cost}}}
        for pass:=0;pass<s-1;pass+=1 {
            changed:=false
            for i:=0;i<e;i+=1 {if next[from[i]]<inf&&next[from[i]]+1<next[to[i]] {next[to[i]]=next[from[i]]+1;changed=true}}
            if !changed do break
        }
        if next[accept]<=k {output[pos]=1} else {output[pos]=0}
        for q:=0;q<s;q+=1 {cur[q]=next[q]}
    }
    return i64(t)
}
