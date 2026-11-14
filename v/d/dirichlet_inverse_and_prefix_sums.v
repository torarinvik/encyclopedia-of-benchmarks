module dirichlet_inverse_and_prefix_sums
const dips_mod = i64(998244353)

fn power(base_input i64, exponent_input int) i64 {
    mut base:=base_input; mut exponent:=exponent_input; mut result:=i64(1)
    for exponent>0 {
        if exponent & 1 != 0 { result=result*base%dips_mod }
        base=base*base%dips_mod; exponent >>= 1
    }
    return result
}
fn locate(q [15]int, count int, value int) int {
    mut lo:=0; mut hi:=count
    for lo<hi {
        mid:=lo+(hi-lo)/2
        if q[mid]<value { lo=mid+1 } else { hi=mid }
    }
    if lo<count && q[lo]==value { return lo }
    return -1
}
@[export: 'dirichlet_inverse_and_prefix_sums']
fn dirichlet_inverse_and_prefix_sums(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length<2 || length>16 || input[0]<1 || input[0]>64 { return -1 }
        n:=int(input[0]); mut q:=[15]int{}; mut count:=0
        for i:=n; i>0; i-- {
            value:=n/i
            if count==0 || q[count-1]!=value { q[count]=value; count++ }
        }
        if length!=usize(1+count) || input[1]==0 { return -1 }
        for i in 0 .. count { if input[1+i]<0 || input[1+i]>=dips_mod { return -1 } }
        if isnil(output) || capacity<usize(8*count) { return -2 }
        inverse:=power(input[1],998244351); mut g:=[15]i64{}
        for i in 0 .. count {
            x:=q[i]; mut left:=2; mut total:=i64(0)
            for left<=x {
                quotient:=x/left; right:=x/quotient
                hi:=locate(q,count,right); lo:=locate(q,count,left-1); gi:=locate(q,count,quotient)
                if hi<0 || lo<0 || gi<0 { return -1 }
                interval:=(input[1+hi]-input[1+lo]+dips_mod)%dips_mod
                total=(total+interval*g[gi])%dips_mod; left=right+1
            }
            g[i]=((1-total+dips_mod)%dips_mod)*inverse%dips_mod
        }
        for i in 0 .. count {
            bits:=u64(g[i])
            for byte in 0 .. 8 { output[8*i+byte]=u8((bits >> (8*byte)) & 255) }
        }
        return i64(8*count)
    }
}
