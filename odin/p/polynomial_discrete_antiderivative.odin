package polynomial_discrete_antiderivative
import "core:c"
MODULUS :: i64(998244353)
@(export)
polynomial_discrete_antiderivative :: proc "c" (input: [^]i64, length: c.size_t,
                                                 output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<2 || length>33 || input[0]<1 || input[0]>32 { return -1 }
    n:=int(input[0])
    if length!=c.size_t(n+1) { return -1 }
    for i:=0; i<n; i+=1 { if input[1+i]<0 || input[1+i]>=MODULUS { return -1 } }
    if output==nil || capacity<c.size_t(8*(n+1)) { return -2 }
    choose: [33][33]i64; inverse, g: [33]i64
    choose[0][0]=1
    for k:=1; k<=n; k+=1 {
        choose[k][0]=1; choose[k][k]=1
        for j:=1; j<k; j+=1 { choose[k][j]=(choose[k-1][j-1]+choose[k-1][j])%MODULUS }
    }
    inverse[1]=1
    for k:=2; k<=n; k+=1 { inverse[k]=MODULUS-(MODULUS/i64(k))*inverse[int(MODULUS%i64(k))]%MODULUS }
    for j:=n-1; j>=0; j-=1 {
        sum: i64=0
        for k:=j+2; k<=n; k+=1 { sum=(sum+choose[k][j]*g[k])%MODULUS }
        g[j+1]=((input[1+j]-sum+MODULUS)%MODULUS)*inverse[j+1]%MODULUS
    }
    for i:=0; i<=n; i+=1 {
        bits:=u64(g[i])
        for byte:=0; byte<8; byte+=1 { output[8*i+byte]=u8((bits >> u64(8*byte)) & 255) }
    }
    return i64(8*(n+1))
}
