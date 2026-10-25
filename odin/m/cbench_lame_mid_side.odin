package cbench_lame_mid_side
import "core:c"

MAX_INPUT :: 65
SQRT2 :: 1.414213562373095048801688724209698079

@(export, link_name="cbench_lame_mid_side")
cbench_lame_mid_side :: proc "c"(input: [^]f64, n: c.size_t, output: [^]f64, cap: c.size_t) -> i64 {
    if input == nil || n < 1 || n > c.size_t(MAX_INPUT+1) do return -1
    for i := 0; i < int(n); i += 1 { if input[i] != input[i] do return -1 }
    if input[0] < 1.0 || input[0] > 32.0 || input[0] != f64(int(input[0])) do return -1
    count := int(input[0])
    if n != c.size_t(1+2*count) do return -1
    for i := 1; i < int(n); i += 1 { if input[i] < -16.0 || input[i] > 16.0 do return -1 }
    staged: [64]f64
    factor := SQRT2*0.5
    for i := 0; i < count; i += 1 {
        left := input[1+i]; right := input[1+count+i]
        staged[2*i]=(left+right)*factor
        staged[2*i+1]=(left-right)*factor
    }
    needed := 2*count
    if output == nil || cap < c.size_t(needed) do return -2
    for i := 0; i < needed; i += 1 { output[i]=staged[i] }
    return i64(needed)
}
