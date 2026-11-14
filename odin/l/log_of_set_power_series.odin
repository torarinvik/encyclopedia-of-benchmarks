package log_of_set_power_series
import "core:c"
MODULUS :: i64(998244353)
@(export)
log_of_set_power_series :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t) -> i64 {
    if input==nil || length<2 || length>33 || input[0]<0 || input[0]>5 { return -1 }
    size:=1 << u64(input[0])
    if length!=c.size_t(1+size) || input[1]!=1 { return -1 }
    for i:=0;i<size;i+=1 { if input[1+i]<0 || input[1+i]>=MODULUS { return -1 } }
    if output==nil || capacity<c.size_t(8*size) { return -2 }
    coefficients:[32]i64
    for mask:=1;mask<size;mask+=1 {
        pivot:=mask & -mask; sub:=(mask-1)&mask; sum:i64=0
        for sub!=0 {
            if sub & pivot != 0 { sum=(sum+coefficients[sub]*input[1+(mask ~ sub)])%MODULUS }
            sub=(sub-1)&mask
        }
        coefficients[mask]=(input[1+mask]-sum+MODULUS)%MODULUS
    }
    for i:=0;i<size;i+=1 {
        bits:=u64(coefficients[i])
        for byte:=0;byte<8;byte+=1 { output[8*i+byte]=u8((bits >> u64(8*byte)) & 255) }
    }
    return i64(8*size)
}
