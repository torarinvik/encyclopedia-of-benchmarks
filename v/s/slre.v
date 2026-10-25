// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
module slre
fn atom(x i64) bool { return (x >= 97 && x <= 122) || x == 46 }
@[export: 'slre']
pub fn slre(values &i64, length usize) i64 {
 if length < 2 { return -2 }
 if unsafe { values[0] < 0 || values[0] > 24 || values[1] < 1 || values[1] > 24 } { return -2 }
 t := usize(unsafe { values[0] }); p := usize(unsafe { values[1] }); ps := 2 + t
 if length != ps + p { return -2 }
 for i in 0 .. t { x := unsafe { values[2+i] }; if x < 97 || x > 122 { return -2 } }
 mut lo := usize(0); mut hi := p; mut ast := false; mut aend := false
 if unsafe { values[ps] == 94 } { ast = true; lo++ }; if lo < hi && unsafe { values[ps+hi-1] == 36 } { aend = true; hi-- }
 mut i := lo; mut non := false
 for i < hi { x := unsafe { values[ps+i] }; if x == 124 { if !non { return -2 }; non = false; i++; continue }; if !atom(x) { return -2 }; non = true; i++; if i < hi && unsafe { values[ps+i] == 63 } { i++ } }
 if !non { return -2 }
 for start := usize(0); start <= t; start++ { if ast && start > 0 { break }; mut b := lo
  for b <= hi { mut e := b; for e < hi && unsafe { values[ps+e] != 124 } { e++; if e < hi && unsafe { values[ps+e] == 63 } { e++ } }; mut q := b; mut pos := start; mut ok := true
   for q < e { x := unsafe { values[ps+q] }; opt := q+1 < e && unsafe { values[ps+q+1] == 63 }; if pos < t && (x == 46 || x == unsafe { values[2+pos] }) { pos++ } else if !opt { ok = false; break }; if opt { q += 2 } else { q++ } }
   if ok && (!aend || pos == t) { return i64(pos) }; if e == hi { break }; b = e+1
  }
 }
 return -1
}
