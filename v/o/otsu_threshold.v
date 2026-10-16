@[export: 'otsu_threshold']
pub fn otsu_threshold(v &i64, n usize, outp &u8, cap usize) i64 {
 if n < 2 { return -1 }; count := unsafe { v[0] }; if count < 1 || count > 32 || n != usize(count+1) { return -1 }
 mut hist := [256]int{}; for j in 0 .. int(count) { p := unsafe { v[j+1] }; if p < 0 || p > 255 { return -1 }; hist[int(p)]++ }
 mut total := f64(0); for i in 0 .. 256 { total += f64(i*hist[i]) }
 mut maxv := f64(0); mut sum := f64(0); mut wb := 0; mut threshold := 0
 for i in 0 .. 256 { wb += hist[i]; if wb == 0 { continue }; wf := int(count)-wb; if wf == 0 { break }; sum += f64(i*hist[i]); mb := sum/f64(wb); mf := (total-sum)/f64(wf); variance := f64(wb*wf)*(mb-mf)*(mb-mf); if variance > maxv { maxv=variance; threshold=i } }
 if cap < usize(count) || isnil(outp) { return -2 }
 for j in 0 .. int(count) { unsafe { outp[j] = if v[j+1] > i64(threshold) { u8(255) } else { u8(0) } } }
 return count
}
