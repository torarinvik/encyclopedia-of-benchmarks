module polynomial_discrete_antiderivative
const pda_mod=i64(998244353)
@[export: 'polynomial_discrete_antiderivative']
fn polynomial_discrete_antiderivative(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length<2 || length>33 || input[0]<1 || input[0]>32 { return -1 }
        n:=int(input[0])
        if length!=usize(n+1) { return -1 }
        for i in 0 .. n { if input[1+i]<0 || input[1+i]>=pda_mod { return -1 } }
        if isnil(output) || capacity<usize(8*(n+1)) { return -2 }
        mut choose:=[1089]i64{}; mut inverse:=[33]i64{}; mut g:=[33]i64{}
        choose[0]=1
        for k in 1 .. n+1 {
            choose[33*k]=1; choose[33*k+k]=1
            for j in 1 .. k { choose[33*k+j]=(choose[33*(k-1)+j-1]+choose[33*(k-1)+j])%pda_mod }
        }
        inverse[1]=1
        for k in 2 .. n+1 { inverse[k]=pda_mod-(pda_mod/i64(k))*inverse[int(pda_mod%i64(k))]%pda_mod }
        for j:=n-1; j>=0; j-- {
            mut sum:=i64(0)
            for k in j+2 .. n+1 { sum=(sum+choose[33*k+j]*g[k])%pda_mod }
            g[j+1]=((input[1+j]-sum+pda_mod)%pda_mod)*inverse[j+1]%pda_mod
        }
        for i in 0 .. n+1 {
            bits:=u64(g[i])
            for byte in 0 .. 8 { output[8*i+byte]=u8((bits >> (8*byte)) & 255) }
        }
        return i64(8*(n+1))
    }
}
