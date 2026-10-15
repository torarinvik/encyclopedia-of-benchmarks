import math
const epsilon = 1.0e-7
const min_width = 2.0e-7
fn objective(id int, x f64) f64 { if id == 0 { return (x - 2.0) * (x - 2.0) }; return math.cos(x) }
@[export: 'golden_search_extrema']
pub fn golden_search_extrema(objective_id f64, left f64, right f64) f64 {
 if objective_id != 0.0 && objective_id != 1.0 { return -1.0 }
 if objective_id == 0.0 && (!(left >= 0.0 && left <= 4.0) || !(right >= 0.0 && right <= 4.0)) { return -1.0 }
 if objective_id == 1.0 && (!(left >= 2.0 && left <= 4.0) || !(right >= 2.0 && right <= 4.0)) { return -1.0 }
 mut a := left
 mut b := right
 if a > b { tmp := a; a = b; b = tmp }
 id := int(objective_id)
 extremum := 2.0
 if id == 1 { extremum = math.pi }
 if b - a < min_width || !(a < extremum && extremum < b) { return -1.0 }
 mut mean := f64(1.0 / 0.0)
 mut previous_mean := f64(1.0 / 0.0)
 phi := 1.61803400516510009765625
 for i := 0; i < 128 && math.abs(b - a) > epsilon; i++ {
  previous_mean = mean
  ratio := (b - a) / phi
  c := b - ratio
  d := a + ratio
  if objective(id, c) < objective(id, d) { b = d } else { a = c }
  mean = (a + b) / 2.0
 }
 return previous_mean
}
