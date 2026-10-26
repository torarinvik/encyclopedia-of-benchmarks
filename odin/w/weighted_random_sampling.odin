package weighted_random_sampling
import "core:c"

MAX_N :: 16
MAX_INPUT :: 50

power :: proc(base, exponent: i64) -> i64 {
    result: i64 = 1
    for i: i64 = 0; i < exponent; i += 1 { result *= base }
    return result
}
put64 :: proc(out: [^]u8, pos: int, value: i64) {
    bits := u64(value)
    for j := 0; j < 8; j += 1 { out[pos+j] = u8(bits & 255); bits >>= 8 }
}

@(export)
weighted_random_sampling :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > MAX_INPUT do return -1
    n64 := input[0]; m64 := input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > n64 || length != c.size_t(2+3*n64) do return -1
    n := int(n64); m := int(m64)
    weights: [MAX_N]i64; nums: [MAX_N]i64; dens: [MAX_N]i64
    for i := 0; i < n; i += 1 {
        weights[i]=input[2+3*i]; nums[i]=input[3+3*i]; dens[i]=input[4+3*i]
        if weights[i]<1 || weights[i]>3 || nums[i]<1 || nums[i]>=dens[i] || dens[i]>100 do return -1
    }
    bytes := 8*m
    if output == nil || capacity < c.size_t(bytes) do return -2
    available: [MAX_N]i64; chosen: [MAX_N]i64
    for i := 0; i < n; i += 1 { available[i]=i64(i) }
    for rank := 0; rank < m; rank += 1 {
        best := 0
        for i := 1; i < n-rank; i += 1 {
            left:=int(available[i]); right:=int(available[best])
            lhs:=power(nums[left],weights[right])*power(dens[right],weights[left])
            rhs:=power(nums[right],weights[left])*power(dens[left],weights[right])
            if lhs>rhs || (lhs==rhs && left<right) { best=i }
        }
        chosen[rank]=available[best]
        for i:=best; i+1<n-rank; i+=1 { available[i]=available[i+1] }
    }
    for i:=0; i<m; i+=1 { put64(output,8*i,chosen[i]) }
    return i64(bytes)
}
