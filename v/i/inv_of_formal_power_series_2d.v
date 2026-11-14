module inv_of_formal_power_series_2d
const fps2d_mod=i64(998244353)
fn power(initial i64) i64 {
    mut x:=initial; mut exponent:=998244351; mut result:=i64(1)
    for exponent>0 {
        if exponent & 1 != 0 { result=result*x%fps2d_mod }
        x=x*x%fps2d_mod; exponent >>= 1
    }
    return result
}
@[export: 'inv_of_formal_power_series_2d']
fn inv_of_formal_power_series_2d(input &i64,length usize,output &u8,capacity usize) i64 {
    unsafe {
        if isnil(input) || length<3 || length>66 || input[0]<1 || input[0]>8 || input[1]<1 || input[1]>8 { return -1 }
        n:=int(input[0]); m:=int(input[1])
        if length!=usize(2+n*m) || input[2]==0 { return -1 }
        for i in 0 .. n*m { if input[2+i]<0 || input[2+i]>=fps2d_mod { return -1 } }
        if isnil(output) || capacity<usize(8*n*m) { return -2 }
        mut g:=[64]i64{}; inverse:=power(input[2]); g[0]=inverse
        for i in 0 .. n { for j in 0 .. m {
            if i==0 && j==0 { continue }
            mut sum:=i64(0)
            for a in 0 .. i+1 { for b in 0 .. j+1 {
                if a!=0 || b!=0 { sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%fps2d_mod }
            }}
            g[i*m+j]=((fps2d_mod-sum)%fps2d_mod)*inverse%fps2d_mod
        }}
        for i in 0 .. n*m {
            bits:=u64(g[i])
            for byte in 0 .. 8 { output[8*i+byte]=u8((bits >> (8*byte)) & 255) }
        }
        return i64(8*n*m)
    }
}
