package spatial_motif_same_type_contact_pmf

import "core:c"

MAX_LENGTH :: 16
MAX_SUPPORT :: 17

choose_value :: proc "contextless" (n, k0: int) -> i64 {
    if k0<0 || k0>n do return 0
    k:=k0;if k>n-k { k=n-k }
    result:i64=1
    for i:=1; i<=k; i+=1 { result=result*i64(n-k+i)/i64(i) }
    return result
}
gcd_value :: proc "contextless" (a0,b0:i64) -> i64 {
    a,b:=a0,b0
    for b!=0 { r:=a%b;a=b;b=r }
    return a
}
put_i64 :: proc "contextless" (output:[^]u8,word:int,value:i64) {
    bits:=u64(value)
    for byte:=0;byte<8;byte+=1 { output[word*8+byte]=u8((bits>>(byte*8))&255) }
}

@(export)
spatial_motif_same_type_contact_pmf :: proc "c" (input:[^]i64,input_length:c.size_t,
        output:[^]u8,output_capacity:c.size_t)->i64 {
    if input==nil || input_length!=3 do return -1
    l0,x10,x20:=input[0],input[1],input[2]
    if l0<1 || l0>MAX_LENGTH || x10<0 || x10>l0 || x20<0 || x20>l0 do return -1
    l,x1,x2:=int(l0),int(x10),int(x20)
    low:=max(0,x1+x2-l);high:=min(x1,x2)
    denominator:=choose_value(l,x2)
    numerators:[MAX_SUPPORT]i64
    for i:=low;i<=high;i+=1 { numerators[i-low]=choose_value(x1,i)*choose_value(l-x1,x2-i) }
    expected_num:=i64(x1*x2);expected_den:=i64(l);divisor:=gcd_value(expected_num,expected_den)
    expected_num/=divisor;expected_den/=divisor
    count:=high-low+1;bytes:=c.size_t((3+count+2)*8)
    if output==nil || output_capacity<bytes do return -2
    put_i64(output,0,i64(low));put_i64(output,1,i64(high));put_i64(output,2,denominator)
    for i:=0;i<count;i+=1 { put_i64(output,3+i,numerators[i]) }
    put_i64(output,3+count,expected_num);put_i64(output,4+count,expected_den)
    return i64(bytes)
}
