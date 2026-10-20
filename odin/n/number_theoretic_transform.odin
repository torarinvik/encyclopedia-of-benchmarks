// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
package number_theoretic_transform
import "core:c"
MODULUS :: i64(998244353)
mod_pow :: proc(a_value, exponent_value: i64) -> i64 { a, exponent, result := a_value, exponent_value, i64(1); for exponent > 0 { if (exponent & 1) != 0 { result = result*a % MODULUS }; a=a*a%MODULUS; exponent >>= 1 }; return result }
@(export)
number_theoretic_transform :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > 65 do return -1
    n_value := input[0]
    if n_value < 1 || n_value > 64 || (n_value & (n_value-1)) != 0 || input_length != c.size_t(n_value+1) do return -1
    n := int(n_value); a: [64]i64
    for i in 0..<n { if input[i+1] < 0 || input[i+1] >= MODULUS do return -1; a[i] = input[i+1] }
    if output == nil || output_capacity < c.size_t(4*n) do return -2
    j := 0
    for i in 1..<n { bit := n/2; for (j & bit) != 0 { j ^= bit; bit >>= 1 }; j ^= bit; if i < j { a[i],a[j] = a[j],a[i] } }
    length := 2
    for length <= n {
        step := mod_pow(3,(MODULUS-1)/i64(length)); base := 0
        for base < n { w := i64(1); for k in 0..<length/2 { u:=a[base+k]; v:=a[base+k+length/2]*w%MODULUS; a[base+k]=(u+v)%MODULUS; a[base+k+length/2]=(u-v+MODULUS)%MODULUS; w=w*step%MODULUS }; base += length }
        length *= 2
    }
    for i in 0..<n { x:=u32(a[i]); for b in 0..<4 { output[4*i+b]=u8(x >> u32(8*b)) } }
    return i64(4*n)
}
