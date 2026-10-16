module dimensionality_reduction_lda
import math
@[export: 'dimensionality_reduction_lda']
pub fn dimensionality_reduction_lda(v &f64, n usize, mut out &f64, cap usize) i64 {
 unsafe {
  if v == nil || n < 16 || v[0] != 2 || v[2] != 2 || v[3] != 1 || v[1] < 4 || v[1] > 8 || math.floor(v[1]) != v[1] { return -1 }
  m := int(v[1])
  if n != usize(4 + 3*m) { return -1 }
  base := 4 + 2*m
  mut x := [8]f64{}
  mut y := [8]f64{}
  mut mx0 := 0.0
  mut my0 := 0.0
  mut mx1 := 0.0
  mut my1 := 0.0
  mut c0 := 0
  mut c1 := 0
  for i in 0 .. m {
   x[i] = v[4+i]
   y[i] = v[4+m+i]
   lab := v[base+i]
   if x[i] != x[i] || y[i] != y[i] || math.abs(x[i]) > 10000 || math.abs(y[i]) > 10000 { return -1 }
   if lab == 0 { c0++; mx0 += x[i]; my0 += y[i] }
   else if lab == 1 { c1++; mx1 += x[i]; my1 += y[i] }
   else { return -1 }
  }
  if c0 < 2 || c1 < 2 { return -1 }
  mx0 /= f64(c0); my0 /= f64(c0); mx1 /= f64(c1); my1 /= f64(c1)
  mut a := 0.0
  mut b := 0.0
  mut d := 0.0
  for i in 0 .. m {
   mut dx := x[i] - mx0
   mut dy := y[i] - my0
   if v[base+i] == 1 { dx = x[i]-mx1; dy = y[i]-my1 }
   a += dx*dx; b += dx*dy; d += dy*dy
  }
  a /= f64(m); b /= f64(m); d /= f64(m)
  det := a*d - b*b
  if det <= 1e-12 { return -1 }
  dx := mx1-mx0; dy := my1-my0
  mut w0 := (d*dx-b*dy)/det
  mut w1 := (a*dy-b*dx)/det
  norm := math.sqrt(w0*w0+w1*w1)
  if norm <= 1e-12 { return -1 }
  w0 /= norm; w1 /= norm
  if w0 < 0 || (math.abs(w0) <= 1e-14 && w1 < 0) { w0 = -w0; w1 = -w1 }
  if out == nil || cap < usize(m) { return -2 }
  for i in 0 .. m { out[i] = w0*x[i] + w1*y[i] }
  return i64(m)
 }
}
