// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
package relaxed_convolution
import "core:c"
MODULUS :: i64(998244353)
@(export)
relaxed_convolution :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > 33 do return -1
    n_value := input[0]; if n_value < 1 || n_value > 16 || input_length != c.size_t(1+2*n_value) do return -1
    n := int(n_value); a,b,c_values: [16]i64
    for i in 0..<n { a[i]=input[1+i]; b[i]=input[1+n+i]; if a[i]<0 || a[i]>=MODULUS || b[i]<0 || b[i]>=MODULUS do return -1 }
    if output == nil || output_capacity < c.size_t(4*n) do return -2
    for index in 0..<n {
        c_values[index]=(c_values[index]+a[index]*b[0])%MODULUS
        if index>0 { c_values[index]=(c_values[index]+b[index]*a[0])%MODULUS }
        q:=index+1; d:=1
        for d<=q {
            if q%(2*d)==d {
                end_index:=min(q+d,n)
                if q==d {
                    for i in q..<end_index { target:=d+i-q; for r in 0..<d { y:=target-r; if y<d { c_values[i]=(c_values[i]+a[r]*b[y])%MODULUS } } }
                } else {
                    for i in q..<end_index { target:=d+i-q; for r in 0..<d { y:=target-r; if y<2*d { c_values[i]=(c_values[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%MODULUS } } }
                }
            }
            d*=2
        }
    }
    for i in 0..<n { x:=u32(c_values[i]); for j in 0..<4 { output[4*i+j]=u8(x>>(8*j)) } }
    return i64(4*n)
}
