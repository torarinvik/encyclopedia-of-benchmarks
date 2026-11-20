package lz77_lpf_suffix_array
import "core:c"

Max_Text :: 32
Max_Input :: 34
Max_Output :: 512

suffix_less :: proc(text: [^]i64, n, a0, b0: int) -> bool {
    a, b := a0, b0
    for a < n && b < n {
        if text[a] != text[b] do return text[a] < text[b]
        a += 1; b += 1
    }
    return a == n && b != n
}

lcp :: proc(text: [^]i64, n: int, source: i64, target: int) -> int {
    if source < 0 do return 0
    length := 0
    p := int(source)
    for target+length < n && text[p+length] == text[target+length] { length += 1 }
    return length
}

put64 :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for i in 0..<8 { out[at+i] = u8(bits & 255); bits >>= 8 }
}

@(export)
lz77_lpf_suffix_array :: proc "c"(input: [^]i64, len: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || len < 1 || len > Max_Input do return -1
    if input[0] < 0 || input[0] > Max_Text do return -1
    n := int(input[0])
    if len != c.size_t(n+1) do return -1
    text: [Max_Text]i64
    for i in 0..<n {
        if input[i+1] < 0 || input[i+1] > 255 do return -1
        text[i] = input[i+1]
    }
    sa, inverse, stack: [Max_Text]int
    previous, following: [Max_Text]int
    for i in 0..<n { sa[i]=i; previous[i]=-1; following[i]=-1 }
    for i in 1..<n {
        value := sa[i]; j := i
        for j > 0 && suffix_less(&text[0], n, value, sa[j-1]) { sa[j]=sa[j-1]; j-=1 }
        sa[j]=value
    }
    for r in 0..<n { inverse[sa[r]]=r }
    top := 0
    for r in 0..<n {
        for top > 0 && sa[stack[top-1]] > sa[r] { top-=1 }
        if top > 0 { previous[r]=stack[top-1] }
        stack[top]=r; top+=1
    }
    top=0
    for rr:=n; rr>0; rr-=1 {
        r:=rr-1
        for top > 0 && sa[stack[top-1]] > sa[r] { top-=1 }
        if top > 0 { following[r]=stack[top-1] }
        stack[top]=r; top+=1
    }
    staged: [Max_Output]u8
    pairs, pos := 0, 0
    for pos<n {
        r:=inverse[pos]
        psv:i64=-1; nsv:i64=-1
        if previous[r]>=0 { psv=i64(sa[previous[r]]) }
        if following[r]>=0 { nsv=i64(sa[following[r]]) }
        lp:=lcp(&text[0],n,psv,pos);ln:=lcp(&text[0],n,nsv,pos)
        source:=psv;matched:=lp
        if ln>lp { source=nsv;matched=ln }
        if matched==0 { source=-1 }
        put64(&staged[0],pairs*16,source)
        put64(&staged[0],pairs*16+8,i64(matched))
        pairs+=1
        if matched>0 { pos+=matched } else { pos+=1 }
    }
    bytes:=pairs*16
    if output==nil||capacity<c.size_t(bytes) do return -2
    for i in 0..<bytes { output[i]=staged[i] }
    return i64(bytes)
}
