package inv_of_formal_power_series_2d
import "core:c"
MODULUS :: i64(998244353)
power :: proc(initial: i64) -> i64 {
    x:=initial; exponent:=998244351; result:=i64(1)
    for exponent>0 {
        if exponent & 1 != 0 { result=result*x%MODULUS }
        x=x*x%MODULUS; exponent >>= 1
    }
    return result
}
@(export)
inv_of_formal_power_series_2d :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t) -> i64 {
    if input==nil || length<3 || length>66 || input[0]<1 || input[0]>8 || input[1]<1 || input[1]>8 { return -1 }
    n,m:=int(input[0]),int(input[1])
    if length!=c.size_t(2+n*m) || input[2]==0 { return -1 }
    for i:=0;i<n*m;i+=1 { if input[2+i]<0 || input[2+i]>=MODULUS { return -1 } }
    if output==nil || capacity<c.size_t(8*n*m) { return -2 }
    g: [64]i64; inverse:=power(input[2]); g[0]=inverse
    for i:=0;i<n;i+=1 { for j:=0;j<m;j+=1 {
        if i==0 && j==0 { continue }
        sum: i64=0
        for a:=0;a<=i;a+=1 { for b:=0;b<=j;b+=1 {
            if a!=0 || b!=0 { sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%MODULUS }
        }}
        g[i*m+j]=((MODULUS-sum)%MODULUS)*inverse%MODULUS
    }}
    for i:=0;i<n*m;i+=1 {
        bits:=u64(g[i])
        for byte:=0;byte<8;byte+=1 { output[8*i+byte]=u8((bits >> u64(8*byte)) & 255) }
    }
    return i64(8*n*m)
}
