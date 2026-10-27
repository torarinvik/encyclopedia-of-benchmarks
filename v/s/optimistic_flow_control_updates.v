module optimistic_flow_control_updates

const max_n = 3
const max_l = 4
const max_input = 20
const max_output = 48
const max_updates = 6
const scale = i64(46656)

fn gcd64(a0 i64, b0 i64) i64 {
	mut a := a0
	mut b := b0
	for b != 0 { r := a % b; a = b; b = r }
	return a
}
fn put64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[position+byte] = u8((bits >> (8*byte)) & 255) }
	}
}

@[export: 'optimistic_flow_control_updates']
pub fn optimistic_flow_control_updates(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > max_input { return -1 }
		n64, l64, mode64, q64 := input[0], input[1], input[2], input[3]
		if n64 < 2 || n64 > max_n || l64 < 1 || l64 > max_l || mode64 < 0 || mode64 > 3 || q64 < 1 || q64 > max_updates { return -1 }
		n, links, mode, updates := int(n64), int(l64), int(mode64), int(q64)
		if length != usize(4+links+n*links) { return -1 }
		mut cap := [max_l]i64{init: 0}
		mut path := [max_n*max_l]bool{init: false}
		mut rate := [max_n]i64{init: 0}
		for e in 0 .. links { cap[e] = input[4+e]; if cap[e] < 1 || cap[e] > 16 { return -1 } }
		for s in 0 .. n {
			mut used := false
			for e in 0 .. links {
				bit := input[4+links+s*links+e]
				if bit != 0 && bit != 1 { return -1 }
				path[s*max_l+e] = bit == 1
				if bit == 1 { used = true }
			}
			if !used { return -1 }
		}
		output_bytes := 16*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for step in 0 .. updates {
			mut session := 0
			if mode == 0 { session = step%n }
			else if mode == 1 { for s in 1 .. n { if rate[s] < rate[session] { session=s } } }
			else if mode == 2 {
				mut found := false
				for s in 0 .. n {
					if !found {
						mut local := true
						for j in 0 .. n {
							if j != s && local {
								mut shares := false
								for e in 0 .. links { if path[s*max_l+e] && path[j*max_l+e] { shares=true } }
								if shares && (rate[j]<rate[s] || (rate[j]==rate[s] && j<s)) { local=false }
							}
						}
						if local { session=s; found=true }
					}
				}
			} else {
				mut selected := links
				mut best_load := i64(0)
				for e in 0 .. links {
					mut load := i64(0); mut used := false
					for s in 0 .. n { if path[s*max_l+e] { load+=rate[s]; used=true } }
					if used && (selected==links || load*cap[selected]>best_load*cap[e]) { selected=e; best_load=load }
				}
				for s in 0 .. n { if path[s*max_l+selected] { session=s; break } }
			}
			mut best := i64(9223372036854775807)
			mut bottleneck := links
			for e in 0 .. links {
				if path[session*max_l+e] {
					mut fixed := i64(0); mut active := 1
					for j in 0 .. n { if j!=session && path[j*max_l+e] { if rate[j]<=rate[session] { fixed+=rate[j] } else { active++ } } }
					mut level := rate[session]
					mut candidate := level
					for _ in 0 .. n {
						numerator := cap[e]*scale-fixed
						if numerator<0 || numerator%i64(active)!=0 { return -1 }
						candidate=numerator/i64(active)
						if candidate<level { return -1 }
						mut next := i64(9223372036854775807)
						for j in 0 .. n { if j!=session && path[j*max_l+e] && rate[j]>level && rate[j]<next { next=rate[j] } }
						if next==i64(9223372036854775807) || candidate<=next { break }
						mut saturated := 0
						for j in 0 .. n { if j!=session && path[j*max_l+e] && rate[j]==next { saturated++ } }
						fixed+=i64(saturated)*next; active-=saturated; level=next
					}
					if candidate<best { best=candidate; bottleneck=e }
				}
			}
			if bottleneck==links { return -1 }
			rate[session]=best
			for j in 0 .. n { if j!=session && path[j*max_l+bottleneck] && rate[j]>best { rate[j]=best } }
		}
		mut staged := [max_output]u8{init: 0}
		for s in 0 .. n { divisor:=gcd64(rate[s],scale); put64(&staged[0],16*s,rate[s]/divisor); put64(&staged[0],16*s+8,scale/divisor) }
		for b in 0 .. output_bytes { output[b]=staged[b] }
		return i64(output_bytes)
	}
}
