module optimal_job_scheduling

@[export: 'optimal_job_scheduling']
pub fn optimal_job_scheduling(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 4 || length > 194 { return -1 }
	p_raw := unsafe { values[0] }; m_raw := unsafe { values[1] }
	if p_raw < 1 || p_raw > 16 || m_raw < 1 || m_raw > 8 { return -1 }
	p := int(p_raw); m := int(m_raw)
	if length != usize(2+p*m+m*m) { return -1 }
	for i in 2 .. int(length) { x := unsafe { values[i] }; if x < 0 || x > 1000 { return -1 } }
	mut cost := []int{len: p*m}
	for j in 0 .. m { cost[j] = int(unsafe { values[2+j] }) }
	for i in 1 .. p { for j in 0 .. m { mut best := 2147483647; for k in 0 .. m { candidate := cost[(i-1)*m+k] + int(unsafe { values[2+p*m+k*m+j] }) + int(unsafe { values[2+i*m+j] }); if candidate < best { best = candidate } }; cost[i*m+j] = best } }
	mut result := ''
	for i in 0 .. p { if i > 0 { result += '\n' }; for j in 0 .. m { if j > 0 { result += ',' }; result += cost[i*m+j].str() } }
	if usize(result.len) > capacity || (result.len > 0 && isnil(output)) { return -2 }
	for i in 0 .. result.len { unsafe { output[i] = result[i] } }
	return i64(result.len)
}
