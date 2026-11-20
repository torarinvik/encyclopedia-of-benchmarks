module jacobson_matthews_latin_square_chain

const max_n = 4
const max_cells = 64
const max_moves = 48
const max_words = 66

struct Move {
mut:
	i int
	j int
	k int
	ip int
	jp int
	kp int
}

fn at(n int, i int, j int, k int) int { return (i*n+j)*n+k }

fn select_move(tensor [max_cells]i64, n int, choice int) ?Move {
	mut moves := [max_moves]Move{}
	mut defects := 0
	mut pi := 0
	mut pj := 0
	mut pk := 0
	mut count := 0
	for i in 0 .. n { for j in 0 .. n { for k in 0 .. n {
		if tensor[at(n,i,j,k)] == -1 { defects++; pi=i; pj=j; pk=k }
	}}}
	if defects > 1 { return none }
	if defects == 1 {
		for ip in 0 .. n { for jp in 0 .. n { for kp in 0 .. n {
			if ip != pi && jp != pj && kp != pk && tensor[at(n,pi,pj,kp)] == 1 &&
				tensor[at(n,pi,jp,pk)] == 1 && tensor[at(n,ip,pj,pk)] == 1 {
				moves[count] = Move{pi,pj,pk,ip,jp,kp}; count++
			}
		}}}
		if count != 8 { return none }
	} else {
		for i in 0 .. n { for j in 0 .. n { for k in 0 .. n {
			if tensor[at(n,i,j,k)] != 0 { continue }
			mut ip := n; mut jp := n; mut kp := n
			for x in 0 .. n { if tensor[at(n,x,j,k)] == 1 { ip=x } }
			for x in 0 .. n { if tensor[at(n,i,x,k)] == 1 { jp=x } }
			for x in 0 .. n { if tensor[at(n,i,j,x)] == 1 { kp=x } }
			if ip == n || jp == n || kp == n { return none }
			moves[count] = Move{i,j,k,ip,jp,kp}; count++
		}}}
		if count != n*n*n-n*n { return none }
	}
	if choice < 0 || choice >= count { return none }
	return moves[choice]
}

fn apply_choice(mut tensor [max_cells]i64, n int, choice int) bool {
	m := select_move(tensor,n,choice) or { return false }
	tensor[at(n,m.i,m.j,m.k)]++
	tensor[at(n,m.ip,m.jp,m.k)]++
	tensor[at(n,m.ip,m.j,m.kp)]++
	tensor[at(n,m.i,m.jp,m.kp)]++
	tensor[at(n,m.ip,m.j,m.k)]--
	tensor[at(n,m.i,m.jp,m.k)]--
	tensor[at(n,m.i,m.j,m.kp)]--
	tensor[at(n,m.ip,m.jp,m.kp)]--
	return true
}

fn write_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8((bits >> (byte*8)) & 255) } }
}

@[export: 'jacobson_matthews_latin_square_chain']
pub fn jacobson_matthews_latin_square_chain(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 14 { return -1 }
		nv := input[0]; sv := input[1]
		if nv < 2 || nv > max_n || sv < 0 || sv > 12 || length != usize(2+sv) { return -1 }
		n := int(nv); steps := int(sv)
		mut tensor := [max_cells]i64{}
		for i in 0 .. n { for j in 0 .. n { tensor[at(n,i,j,(i+j)%n)] = 1 } }
		for s in 0 .. steps {
			choice := input[2+s]
			if choice < 0 || choice >= max_moves || !apply_choice(mut tensor,n,int(choice)) { return -1 }
		}
		word_count := 2+n*n*n
		output_bytes := word_count*8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut words := [max_words]i64{}
		words[0] = nv; words[1] = sv
		for i in 0 .. n*n*n { words[2+i] = tensor[i] }
		for i in 0 .. word_count { write_i64_le(output,i*8,words[i]) }
		return i64(output_bytes)
	}
}
