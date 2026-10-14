module lerp

// Binary64 interpolation in the classic start + t * (end - start) form.
@[export: 'lerp']
pub fn lerp(start f64, end f64, t f64) f64 {
	return start + t * (end - start)
}
