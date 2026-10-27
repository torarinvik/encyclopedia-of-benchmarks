package integer_sequence_codes

import "core:c"

MAX_N :: 32
MAX_INPUT :: 35
MAX_OUTPUT :: 4096
MAX_RESULT :: 512

emit_bit :: proc(out: [^]u8, used: ^int, value: bool) {
	out[used^] = if value {u8('1')} else {u8('0')}
	used^ += 1
}
emit_byte :: proc(out: [^]u8, used: ^int, value: u8) { out[used^] = value; used^ += 1 }
emit_number :: proc(out: [^]u8, used: ^int, value: u64, width: int) {
	for shift := width-1; shift >= 0; shift -= 1 { emit_bit(out, used, ((value >> u64(shift)) & 1) != 0) }
}
emit_unary :: proc(out: [^]u8, used: ^int, value: u64) {
	for i := u64(0); i < value; i += 1 { emit_bit(out, used, true) }
	emit_bit(out, used, false)
}
floor_log2 :: proc(value: u64) -> int {
	remaining := value
	width := -1
	for remaining != 0 { width += 1; remaining >>= 1 }
	return width
}
emit_minimal :: proc(out: [^]u8, used: ^int, value, universe: u64) {
	if universe == 1 { return }
	low_width := floor_log2(universe)
	short_count := (u64(1) << u64(low_width+1)) - universe
	if value < short_count { emit_number(out, used, value, low_width) }
	else { emit_number(out, used, value+short_count, low_width+1) }
}
emit_gamma :: proc(out: [^]u8, used: ^int, value: u64) {
	shifted := value+1
	width := floor_log2(shifted)
	emit_unary(out, used, u64(width))
	emit_number(out, used, shifted-(u64(1)<<u64(width)), width)
}
emit_delta :: proc(out: [^]u8, used: ^int, value: u64) {
	shifted := value+1
	width := floor_log2(shifted)
	emit_gamma(out, used, u64(width))
	emit_number(out, used, shifted-(u64(1)<<u64(width)), width)
}
emit_interpolative :: proc(out: [^]u8, used: ^int, input: [^]i64, left, right: int, low, high: i64) {
	if left >= right { return }
	middle := left+(right-left-1)/2
	value := input[3+middle]
	lower := low+i64(middle-left)
	upper := high-i64(right-middle-1)
	emit_minimal(out, used, u64(value-lower), u64(upper-lower))
	emit_interpolative(out, used, input, left, middle, low, value)
	emit_interpolative(out, used, input, middle+1, right, value+1, high)
}
emit_simple9 :: proc(out: [^]u8, used: ^int, input: [^]i64, n: int) {
	slots := [9]int{28,14,9,7,5,4,3,2,1}
	widths := [9]int{1,2,3,4,5,7,9,14,28}
	position := 0
	for position < n {
		selector, take, width := 0,0,0
		for s := 0; s < 9; s += 1 {
			count := min(slots[s], n-position)
			fits := true
			for j := 0; j < count; j += 1 { if u64(input[3+position+j]) >= (u64(1)<<u64(widths[s])) { fits=false } }
			if fits { selector=s; take=count; width=widths[s]; break }
		}
		word := u64(selector)<<28
		for j := 0; j < take; j += 1 { word |= u64(input[3+position+j]) << u64(28-width*(j+1)) }
		emit_number(out,used,word,32)
		position += take
	}
}

@(export)
integer_sequence_codes :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT { return -1 }
	mode0, n0, parameter := input[0], input[1], input[2]
	if mode0 < 0 || mode0 > 9 || n0 < 1 || n0 > MAX_N || length != c.size_t(n0+3) { return -1 }
	mode, n := int(mode0), int(n0)
	if mode == 0 {
		if parameter != 0 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 31 { return -1 } }
	} else if mode == 1 {
		if parameter < 2 || parameter > 1000000 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] >= parameter { return -1 } }
	} else if mode == 2 || mode == 3 {
		if parameter != 0 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 1000000 { return -1 } }
	} else if mode == 4 {
		if parameter < 1 || parameter > 128 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 127 { return -1 } }
	} else if mode == 7 {
		if parameter != 0 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 1000000 { return -1 } }
	} else if mode == 8 {
		if parameter != 0 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] >= (i64(1)<<28) { return -1 } }
	} else if mode == 9 {
		if parameter < 1 || parameter > 20 { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 1000000 { return -1 } }
	} else {
		if parameter < 2 || parameter > 4096 || n0 > parameter { return -1 }
		for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] >= parameter || (i > 0 && input[2+i] >= input[3+i]) { return -1 } }
	}
	staged: [MAX_OUTPUT]u8
	used := 0
	if mode == 0 {
		for i := 0; i < n; i += 1 { emit_unary(&staged[0], &used, u64(input[3+i])) }
	} else if mode == 1 {
		for i := 0; i < n; i += 1 { emit_minimal(&staged[0], &used, u64(input[3+i]), u64(parameter)) }
	} else if mode == 2 {
		for i := 0; i < n; i += 1 { emit_gamma(&staged[0], &used, u64(input[3+i])) }
	} else if mode == 3 {
		for i := 0; i < n; i += 1 { emit_delta(&staged[0], &used, u64(input[3+i])) }
	} else if mode == 4 {
		b := u64(parameter)
		for i := 0; i < n; i += 1 { x := u64(input[3+i]); emit_unary(&staged[0], &used, x/b); emit_minimal(&staged[0], &used, x%b, b) }
	} else if mode == 5 {
		width := 0
		for u64(n)*(u64(1)<<u64(width+1)) <= u64(parameter) { width += 1 }
		bucket_size := u64(1)<<u64(width)
		buckets := int((u64(parameter)+bucket_size-1)/bucket_size)
		counts: [4096]u8
		for i := 0; i < n; i += 1 { counts[u64(input[3+i])/bucket_size] += 1 }
		for bucket := 0; bucket < buckets; bucket += 1 { emit_unary(&staged[0], &used, u64(counts[bucket])) }
		for i := 0; i < n; i += 1 { emit_number(&staged[0], &used, u64(input[3+i])%bucket_size, width) }
	} else if mode == 6 {
		emit_interpolative(&staged[0], &used, input, 0, n, 0, parameter)
	} else if mode == 7 {
		for i := 0; i < n; i += 1 {
			value := u64(input[3+i]); highest := floor_log2(value)
			if highest < 0 { highest=0 } else { highest=(highest/7)*7 }
			for shift := highest; shift >= 0; shift -= 7 {
				byte := u8((value>>u64(shift))&0x7f); if shift != 0 { byte |= 0x80 }
				emit_byte(&staged[0],&used,byte)
			}
		}
	} else if mode == 8 {
		emit_simple9(&staged[0],&used,input,n)
	} else {
		width := int(parameter); low_mask := (u64(1)<<u64(width))-1; exception_count := 0
		for i := 0; i < n; i += 1 { value:=u64(input[3+i]); emit_number(&staged[0],&used,value&low_mask,width); if value >= (u64(1)<<u64(width)) { exception_count += 1 } }
		emit_number(&staged[0],&used,u64(exception_count),6)
		position_width:=0;for (1<<position_width)<n { position_width+=1 }
		for i := 0; i < n; i += 1 { value:=u64(input[3+i]); if value >= (u64(1)<<u64(width)) { emit_number(&staged[0],&used,u64(i),position_width); emit_number(&staged[0],&used,value,20) } }
	}
	if output == nil { return -2 }
	if mode == 7 { if capacity < c.size_t(used) { return -2 }; for i := 0; i < used; i += 1 { output[i]=staged[i] }; return i64(used) }
	bytes:=(used+7)/8;if capacity<c.size_t(bytes){return -2};packed:[MAX_RESULT]u8
	for i:=0;i<used;i+=1{if staged[i]=='1'{packed[i/8]|=u8(1)<<u8(7-i%8)}}
	for i:=0;i<bytes;i+=1{output[i]=packed[i]};return i64(bytes)
}
