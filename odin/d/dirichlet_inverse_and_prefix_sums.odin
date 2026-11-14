package dirichlet_inverse_and_prefix_sums
import "core:c"
MODULUS :: i64(998244353)
power :: proc(base_input: i64, exponent_input: int) -> i64 {
    base, exponent, result := base_input, exponent_input, i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { result=result*base%MODULUS }
        base=base*base%MODULUS; exponent >>= 1
    }
    return result
}
locate :: proc(q: ^[15]int, count, value: int) -> int {
    lo, hi := 0, count
    for lo < hi {
        mid := lo+(hi-lo)/2
        if q[mid] < value { lo=mid+1 } else { hi=mid }
    }
    if lo<count && q[lo]==value { return lo }
    return -1
}
@(export)
dirichlet_inverse_and_prefix_sums :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<2 || length>16 || input[0]<1 || input[0]>64 { return -1 }
    n := int(input[0]); q: [15]int; count := 0
    for i := n; i>0; i-=1 {
        value := n/i
        if count==0 || q[count-1]!=value { q[count]=value; count+=1 }
    }
    if length!=c.size_t(1+count) || input[1]==0 { return -1 }
    for i := 0; i<count; i+=1 { if input[1+i]<0 || input[1+i]>=MODULUS { return -1 } }
    if output==nil || capacity<c.size_t(8*count) { return -2 }
    inverse := power(input[1],998244351); g: [15]i64
    for i := 0; i<count; i+=1 {
        x := q[i]; left := 2; total: i64 = 0
        for left<=x {
            quotient := x/left; right := x/quotient
            hi,lo,gi := locate(&q,count,right),locate(&q,count,left-1),locate(&q,count,quotient)
            if hi<0 || lo<0 || gi<0 { return -1 }
            interval := (input[1+hi]-input[1+lo]+MODULUS)%MODULUS
            total=(total+interval*g[gi])%MODULUS
            left=right+1
        }
        g[i]=((1-total+MODULUS)%MODULUS)*inverse%MODULUS
    }
    for i := 0; i<count; i+=1 {
        bits:=u64(g[i])
        for byte:=0; byte<8; byte+=1 { output[8*i+byte]=u8((bits >> u64(8*byte)) & 255) }
    }
    return i64(8*count)
}
