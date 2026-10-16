package fast_walsh_hadamard_transform
import "core:c"
@(export)
fast_walsh_hadamard_transform :: proc "c" (v: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if v == nil || length < 2 || length > 130 || (v[0] != 0 && v[0] != 1) || v[1] < 1 || v[1] > 128 do return -1
    n := int(v[1]); if (n & (n-1)) != 0 || length != c.size_t(n+2) do return -1
    a: [128]i64
    for i := 0; i < n; i += 1 { if v[i+2] < -10000 || v[i+2] > 10000 do return -1; a[i] = v[i+2] }
    for h := 1; h < n; h *= 2 { for b := 0; b < n; b += 2*h { for j := 0; j < h; j += 1 { x:=a[b+j]; y:=a[b+j+h]; a[b+j]=x+y; a[b+j+h]=x-y } } }
    if v[0] == 1 { for i := 0; i < n; i += 1 { if a[i] % i64(n) != 0 do return -1; a[i] /= i64(n) } }
    if c.size_t(n*8) > capacity || output == nil do return -2
    for i := 0; i < n; i += 1 { x := transmute(u64)a[i]; for k := 0; k < 8; k += 1 { output[i*8+k] = u8((x >> u64(k*8)) & 255) } }
    return i64(n)
}
