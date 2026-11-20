// Independently authored draft; not compiled or run.
package circle_line_intersection_symbolic
import "core:c"

@(export)
circle_line_intersection_symbolic :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 6 do return -1
    for i := 0; i < 6; i += 1 {
        if input[i] < -1000 || input[i] > 1000 do return -1
    }
    x,y,r := input[0],input[1],input[2]
    a,b,c0 := input[3],input[4],input[5]
    if r < 1 || (a == 0 && b == 0) do return -1
    d := a*a+b*b; q := a*x+b*y+c0; h := r*r*d-q*q
    k := i64(0)
    if h == 0 { k = 1 } else if h > 0 { k = 2 }
    words := [7]i64{k,x*d-a*q,y*d-b*q,d,-b,a,h}
    count := 7
    if h < 0 { count = 1 }
    needed := 8*count
    if output == nil || capacity < c.size_t(needed) do return -2
    for i := 0; i < count; i += 1 {
        bits := transmute(u64)words[i]
        for j := 0; j < 8; j += 1 do output[8*i+j] = u8((bits >> uint(8*j)) & 255)
    }
    return i64(needed)
}
