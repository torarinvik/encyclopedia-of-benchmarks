package laplacian_filter
import "core:c"
laplacian_filter :: proc(v: [^]i64, n: c.size_t) -> f64 { if n != 9 { return -1e300 }; for i in 0..<9 { if v[i] < 0 || v[i] > 255 { return -1e300 } }; return f64(4*v[4]-v[1]-v[3]-v[5]-v[7]) }
