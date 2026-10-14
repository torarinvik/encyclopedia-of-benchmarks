package lerp

// Binary64 interpolation in the classic start + t * (end - start) form.
@(export)
lerp :: proc "c" (start, ending, t: f64) -> f64 {
	return start + t * (ending - start)
}
