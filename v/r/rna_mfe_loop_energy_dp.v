module rna_mfe_loop_energy_dp

const max_n = 12
const max_pairs = 36
const table_values = 234
const max_input = 247
const max_output = 112
const inf = i64(1152921504606846976)

fn pair_type(a i64, b i64) int {
	if a == 0 && b == 3 { return 0 }
	if a == 3 && b == 0 { return 1 }
	if a == 1 && b == 2 { return 2 }
	if a == 2 && b == 1 { return 3 }
	if a == 2 && b == 3 { return 4 }
	if a == 3 && b == 2 { return 5 }
	return -1
}

fn lex_less_mask(left u64, right u64, count int) bool {
	mut li := 0
	mut ri := 0
	for {
		for li < count && ((left >> li) & 1) == 0 { li++ }
		for ri < count && ((right >> ri) & 1) == 0 { ri++ }
		if li == count || ri == count { return li == count && ri < count }
		if li != ri { return li < ri }
		li++
		ri++
	}
	return false
}

fn loop_cost(input &i64, n int, kind int, unpaired int, children int) i64 {
	unsafe { return input[1+n+kind*39+unpaired*3+children] }
}

fn put64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@[export: 'rna_mfe_loop_energy_dp']
pub fn rna_mfe_loop_energy_dp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 239 || length > max_input { return -1 }
		n64 := input[0]
		if n64 < 4 || n64 > i64(max_n) || length != usize(1+n64+table_values) { return -1 }
		n := int(n64)
		mut bases := [max_n]i64{}
		for i in 0 .. n { bases[i] = input[1+i]; if bases[i] < 0 || bases[i] > 3 { return -1 } }
		for i in 1+n .. int(length) { if input[i] < -1000 || input[i] > 1000 { return -1 } }
		mut types := [max_n][max_n]int{}
		mut ids := [max_n][max_n]int{}
		for i in 0 .. max_n { for j in 0 .. max_n { types[i][j] = -1; ids[i][j] = -1 } }
		mut pair_i := [max_pairs]int{}
		mut pair_j := [max_pairs]int{}
		mut pair_count := 0
		for i in 0 .. n { for j in i+4 .. n { kind := pair_type(bases[i],bases[j]); if kind >= 0 { types[i][j]=kind; ids[i][j]=pair_count; pair_i[pair_count]=i; pair_j[pair_count]=j; pair_count++ } } }
		mut ve := [max_n][max_n]i64{}
		mut vm := [max_n][max_n]u64{}
		for i in 0 .. max_n { for j in 0 .. max_n { ve[i][j] = inf } }
		for span in 4 .. n { for i in 0 .. n-span {
			j := i+span; kind := types[i][j]; if kind < 0 { continue }
			outer := u64(1) << u32(ids[i][j]); mut best := inf; mut best_mask := u64(0)
			mut candidate := loop_cost(input,n,kind,span-1,0)
			if candidate < best || (candidate == best && lex_less_mask(outer,best_mask,pair_count)) { best=candidate; best_mask=outer }
			for a in i+1 .. j { for b in a+4 .. j {
				if ids[a][b] < 0 || ve[a][b] == inf { continue }
				u := a-i-1+j-b-1; candidate=loop_cost(input,n,kind,u,1)+ve[a][b]; mask:=outer|vm[a][b]
				if candidate < best || (candidate == best && lex_less_mask(mask,best_mask,pair_count)) { best=candidate; best_mask=mask }
			} }
			for a in i+1 .. j { for b in a+4 .. j {
				if ids[a][b] < 0 || ve[a][b] == inf { continue }
				for c in b+1 .. j { for d in c+4 .. j {
					if ids[c][d] < 0 || ve[c][d] == inf { continue }
					u := a-i-1+c-b-1+j-d-1; candidate=loop_cost(input,n,kind,u,2)+ve[a][b]+ve[c][d]; mask:=outer|vm[a][b]|vm[c][d]
					if candidate < best || (candidate == best && lex_less_mask(mask,best_mask,pair_count)) { best=candidate; best_mask=mask }
				} }
			} }
			ve[i][j]=best;vm[i][j]=best_mask
		} }
		mut we := [max_n]i64{}
		mut wm := [max_n]u64{}
		for j in 0 .. n {
			mut best := i64(0); mut best_mask := u64(0)
			if j > 0 { best=we[j-1]; best_mask=wm[j-1] }
			if j >= 4 { for i in 0 .. j-3 {
				if types[i][j] < 0 || ve[i][j] == inf { continue }
				mut prefix := i64(0); mut prefix_mask := u64(0)
				if i > 0 { prefix=we[i-1]; prefix_mask=wm[i-1] }
				value := prefix+ve[i][j]; mask := prefix_mask|vm[i][j]
				if value < best || (value == best && lex_less_mask(mask,best_mask,pair_count)) { best=value; best_mask=mask }
			} }
			we[j]=best;wm[j]=best_mask
		}
		mut count := 0
		for p in 0 .. pair_count { if ((wm[n-1] >> u32(p)) & 1) != 0 { count++ } }
		bytes := 8*(2+2*count)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output]u8{}
		put64(mut staged,0,we[n-1]);put64(mut staged,8,i64(count));mut at:=2
		for p in 0 .. pair_count { if ((wm[n-1] >> u32(p)) & 1) != 0 { put64(mut staged,8*at,i64(pair_i[p]));at++;put64(mut staged,8*at,i64(pair_j[p]));at++ } }
		for byte in 0 .. bytes { output[byte]=staged[byte] }
		return i64(bytes)
	}
}
