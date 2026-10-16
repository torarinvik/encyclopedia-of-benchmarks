module laplacian_filter
@[export: 'laplacian_filter']
fn laplacian_filter(v &i64, n usize) f64 { if n != 9 { return -1e300 }; for i in 0..9 { if v[i] < 0 || v[i] > 255 { return -1e300 } }; return f64(4*v[4]-v[1]-v[3]-v[5]-v[7]) }
