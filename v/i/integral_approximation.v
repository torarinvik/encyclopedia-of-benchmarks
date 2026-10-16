module main

fn sample(id i64, x f64) f64 { if id == 0 { return x * x }; return x * x * x - x * x + 378.0 }
@[export: 'integral_approximation']
pub fn integral_approximation(v &i64, n usize) f64 {
	if n != 4 { return -1.0e300 }
	id := v[0]; li := v[1]; ui := v[2]; di := v[3]
	if id < 0 || id > 1 || li < 0 || ui > 32 || li >= ui || di < 1 || di > 8 { return -1.0e300 }
	lo := f64(li) / 8.0; hi := f64(ui) / 8.0; d := f64(di) / 8.0
	count := int((hi - lo) / d)
	if count > 32 { return -1.0e300 }
	mut total := f64(0)
	for i in 0 .. count { begin := lo + f64(i) * d; finish := lo + f64(i + 1) * d; total += d * (sample(id, begin) + sample(id, finish)) / 2.0 }
	return total
}
