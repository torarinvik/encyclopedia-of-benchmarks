package perfect_numbers
import "core:c"
@(export)
perfect_numbers :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 if v == nil || n != 1 || v[0] < 0 || v[0] > 1_000_000_000 do return -1
 x := v[0]; if x <= 1 do return 0
 total := i64(1); d := i64(2)
 for d <= x/d { if x%d == 0 { total += d; q:=x/d; if d!=q do total+=q }; d+=1 }
 return i64(total==x)
}

