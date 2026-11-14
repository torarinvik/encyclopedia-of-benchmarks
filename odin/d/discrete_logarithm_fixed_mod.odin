package discrete_logarithm_fixed_mod
import "core:c"

@(export)
discrete_logarithm_fixed_mod :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<3 || length>259 { return -1 }
    if input[0]<2 || input[0]>4093 || input[1]<1 || input[1]>=input[0] || input[2]<1 || input[2]>256 { return -1 }
    p:=int(input[0]); g:=int(input[1]); n:=int(input[2])
    if length!=c.size_t(n+3) { return -1 }
    for d:=2;d*d<=p;d+=1 { if p%d==0 { return -1 } }
    for i:=0;i<n;i+=1 { if input[3+i]<1 || input[3+i]>=input[0] { return -1 } }
    table:[4094]i16
    for i:=0;i<p;i+=1 { table[i]=-1 }
    residue:=1
    for exponent:=0;exponent<p-1;exponent+=1 {
        if table[residue]!=-1 { return -1 }
        table[residue]=i16(exponent)
        residue=residue*g%p
    }
    if residue!=1 { return -1 }
    if output==nil || capacity<c.size_t(8*n) { return -2 }
    for i:=0;i<n;i+=1 {
        value:=u64(table[int(input[3+i])])
        for byte:=0;byte<8;byte+=1 { output[8*i+byte]=u8((value >> u64(8*byte)) & 255) }
    }
    return i64(8*n)
}
