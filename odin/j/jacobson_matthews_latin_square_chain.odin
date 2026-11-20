package jacobson_matthews_latin_square_chain

import "core:c"

MAX_N :: 4
MAX_CELLS :: 64
MAX_MOVES :: 48
MAX_WORDS :: 66

Move :: struct { i, j, k, ip, jp, kp: int }

at :: proc(n, i, j, k: int) -> int { return (i*n+j)*n+k }

select_move :: proc(tensor: [MAX_CELLS]i64, n, choice: int, selected: ^Move) -> bool {
	var moves: [MAX_MOVES]Move
	defects, pi, pj, pk, count := 0, 0, 0, 0, 0
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { for k := 0; k < n; k += 1 {
		if tensor[at(n,i,j,k)] == -1 { defects += 1; pi=i; pj=j; pk=k }
	}}}
	if defects > 1 { return false }
	if defects == 1 {
		for ip := 0; ip < n; ip += 1 { for jp := 0; jp < n; jp += 1 { for kp := 0; kp < n; kp += 1 {
			if ip != pi && jp != pj && kp != pk && tensor[at(n,pi,pj,kp)] == 1 &&
				tensor[at(n,pi,jp,pk)] == 1 && tensor[at(n,ip,pj,pk)] == 1 {
				moves[count] = Move{pi,pj,pk,ip,jp,kp}; count += 1
			}
		}}}
		if count != 8 { return false }
	} else {
		for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { for k := 0; k < n; k += 1 {
			if tensor[at(n,i,j,k)] != 0 { continue }
			ip, jp, kp := n, n, n
			for x := 0; x < n; x += 1 { if tensor[at(n,x,j,k)] == 1 { ip=x } }
			for x := 0; x < n; x += 1 { if tensor[at(n,i,x,k)] == 1 { jp=x } }
			for x := 0; x < n; x += 1 { if tensor[at(n,i,j,x)] == 1 { kp=x } }
			if ip == n || jp == n || kp == n { return false }
			moves[count] = Move{i,j,k,ip,jp,kp}; count += 1
		}}}
		if count != n*n*n-n*n { return false }
	}
	if choice < 0 || choice >= count { return false }
	selected^ = moves[choice]
	return true
}

apply_choice :: proc(tensor: ^[MAX_CELLS]i64, n, choice: int) -> bool {
	move: Move
	if !select_move(tensor^,n,choice,&move) { return false }
	m := move
	tensor[at(n,m.i,m.j,m.k)] += 1; tensor[at(n,m.ip,m.jp,m.k)] += 1
	tensor[at(n,m.ip,m.j,m.kp)] += 1; tensor[at(n,m.i,m.jp,m.kp)] += 1
	tensor[at(n,m.ip,m.j,m.k)] -= 1; tensor[at(n,m.i,m.jp,m.k)] -= 1
	tensor[at(n,m.i,m.j,m.kp)] -= 1; tensor[at(n,m.ip,m.jp,m.kp)] -= 1
	return true
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits>>(byte*8))&255) }
}

@(export)
jacobson_matthews_latin_square_chain :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 14 do return -1
	nv, sv := input[0], input[1]
	if nv < 2 || nv > MAX_N || sv < 0 || sv > 12 || length != c.size_t(2+sv) do return -1
	n, steps := int(nv), int(sv)
	var tensor: [MAX_CELLS]i64
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { tensor[at(n,i,j,(i+j)%n)] = 1 } }
	for s := 0; s < steps; s += 1 {
		choice := input[2+s]
		if choice < 0 || choice >= MAX_MOVES || !apply_choice(&tensor,n,int(choice)) do return -1
	}
	word_count := 2+n*n*n
	output_bytes := word_count*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	var words: [MAX_WORDS]i64
	words[0], words[1] = nv, sv
	for i := 0; i < n*n*n; i += 1 { words[2+i] = tensor[i] }
	for i := 0; i < word_count; i += 1 { write_i64_le(output,i*8,words[i]) }
	return i64(output_bytes)
}
