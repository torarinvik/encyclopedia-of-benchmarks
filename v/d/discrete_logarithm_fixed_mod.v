module discrete_logarithm_fixed_mod

@[export: 'discrete_logarithm_fixed_mod']
pub fn discrete_logarithm_fixed_mod(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length<3 || length>259 { return -1 }
        if input[0]<2 || input[0]>4093 || input[1]<1 || input[1]>=input[0] || input[2]<1 || input[2]>256 { return -1 }
        p:=int(input[0]); g:=int(input[1]); n:=int(input[2])
        if length!=usize(n+3) { return -1 }
        for d:=2;d*d<=p;d++ { if p%d==0 { return -1 } }
        for i in 0 .. n { if input[3+i]<1 || input[3+i]>=input[0] { return -1 } }
        mut table:=[4094]i16{}
        for i in 0 .. p { table[i]=-1 }
        mut residue:=1
        for exponent in 0 .. p-1 {
            if table[residue]!=-1 { return -1 }
            table[residue]=i16(exponent)
            residue=residue*g%p
        }
        if residue!=1 { return -1 }
        if isnil(output) || capacity<usize(8*n) { return -2 }
        for i in 0 .. n {
            value:=u64(table[int(input[3+i])])
            for byte in 0 .. 8 { output[8*i+byte]=u8((value >> (8*byte)) & 255) }
        }
        return i64(8*n)
    }
}
