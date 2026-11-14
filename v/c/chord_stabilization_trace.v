fn chord_between(ids [16]int, ring int, left int, item int, right int) bool {
	distance := (ids[item]-ids[left]+ring)%ring
	span := (ids[right]-ids[left]+ring)%ring
	return distance > 0 && (span == 0 || distance < span)
}
@[export: 'chord_stabilization_trace']
pub fn chord_stabilization_trace(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 115 { return -1 }
		if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 64 { return -1 }
		ring := 1 << int(input[0]); n := int(input[1]); q := int(input[2])
		if n > ring || length != usize(3+3*n+q) { return -1 }
		mut ids := [16]int{}; mut succ := [16]int{}; mut pred := [16]int{}
		for i in 0 .. n {
			if input[3+i] < 0 || input[3+i] >= i64(ring) { return -1 }
			if i > 0 && input[3+i] <= i64(ids[i-1]) { return -1 }
			if input[3+n+i] < 0 || input[3+n+i] >= i64(n) || input[3+2*n+i] < -1 || input[3+2*n+i] >= i64(n) { return -1 }
			ids[i] = int(input[3+i]); succ[i] = int(input[3+n+i]); pred[i] = int(input[3+2*n+i])
		}
		for i in 0 .. q { if input[3+3*n+i] < 0 || input[3+3*n+i] >= i64(n) { return -1 } }
		for i in 0 .. q {
			node := int(input[3+3*n+i]); candidate := pred[succ[node]]
			if candidate >= 0 && chord_between(ids, ring, node, candidate, succ[node]) { succ[node] = candidate }
			receiver := succ[node]
			if pred[receiver] < 0 || chord_between(ids, ring, pred[receiver], node, receiver) { pred[receiver] = node }
		}
		if output == nil || capacity < usize(2*n) { return -2 }
		for i in 0 .. n { output[i] = u8(succ[i]); output[n+i] = if pred[i] < 0 { u8(255) } else { u8(pred[i]) } }
		return i64(2*n)
	}
}
