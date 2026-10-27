package randomized_rounding_bernoulli
import "core:c"

MAX_N :: 16
MAX_INPUT :: 65

@(export)
randomized_rounding_bernoulli :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > MAX_INPUT do return -1
    n64 := input[0]
    if n64 < 1 || n64 > MAX_N || length != c.size_t(1+4*n64) do return -1
    n := int(n64)
    staged: [MAX_N]u8
    for i := 0; i < n; i += 1 {
        x_num:=input[1+4*i]; x_den:=input[2+4*i]
        u_num:=input[3+4*i]; u_den:=input[4+4*i]
        if x_den<1 || x_den>32 || x_num<0 || x_num>x_den || u_den<1 || u_den>32 || u_num<0 || u_num>=u_den do return -1
        if u_num*x_den < x_num*u_den { staged[i]=1 } else { staged[i]=0 }
    }
    if output == nil || capacity < c.size_t(n) do return -2
    for i := 0; i < n; i += 1 { output[i]=staged[i] }
    return i64(n)
}
