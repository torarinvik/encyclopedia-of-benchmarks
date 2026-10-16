package otsu_threshold
import "core:c"
@(export)
otsu_threshold :: proc "c" (v: [^]i64, n: c.size_t, outp: [^]u8, cap: c.size_t) -> i64 {
 if v == nil || n < 2 || v[0] < 1 || v[0] > 32 || n != c.size_t(v[0]+1) do return -1
 count := int(v[0]); hist: [256]int
 for j := 0; j < count; j += 1 { p := v[j+1]; if p < 0 || p > 255 do return -1; hist[int(p)] += 1 }
 total: f64 = 0; for i := 0; i < 256; i += 1 { total += f64(i*hist[i]) }
 maxv, sum: f64 = 0, 0; wb, threshold := 0, 0
 for i := 0; i < 256; i += 1 {
  wb += hist[i]; if wb == 0 do continue; wf := count-wb; if wf == 0 do break
  sum += f64(i*hist[i]); mb := sum/f64(wb); mf := (total-sum)/f64(wf); variance := f64(wb*wf)*(mb-mf)*(mb-mf)
  if variance > maxv { maxv = variance; threshold = i }
 }
 if cap < c.size_t(count) || outp == nil do return -2
 for j := 0; j < count; j += 1 { if v[j+1] > i64(threshold) { outp[j] = 255 } else { outp[j] = 0 } }
 return i64(count)
}
