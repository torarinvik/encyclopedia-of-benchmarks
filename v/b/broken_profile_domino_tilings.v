module broken_profile_domino_tilings

const max_states = 256
const modulus = i64(998244353)

@[export: 'broken_profile_domino_tilings']
pub fn broken_profile_domino_tilings(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		h0 := input[0]; w0 := input[1]
		if h0 < 1 || h0 > 64 || w0 < 1 || w0 > 64 || min(h0,w0) > 8 || h0*w0 > 512 { return -1 }
		height := int(max(h0,w0)); width := int(min(h0,w0)); states := 1 << width; full := states-1
		mut dp := [max_states]i64{}; mut next := [max_states]i64{}; dp[0] = 1
		for row in 0 .. height {
			for s in 0 .. states { next[s] = 0 }
			for incoming in 0 .. states {
				if dp[incoming] != 0 {
					for outgoing in 0 .. states {
						if (incoming & outgoing) != 0 || (row+1 == height && outgoing != 0) { continue }
						free := full & ~(incoming | outgoing); mut col := 0; mut valid := true
						for col < width {
							if (free & (1 << col)) != 0 {
								if col+1 >= width || (free & (1 << (col+1))) == 0 { valid = false; break }
								col += 2
							} else { col++ }
						}
						if valid { next[outgoing] = (next[outgoing]+dp[incoming])%modulus }
					}
				}
			}
			dp = next
		}
		return dp[0]
	}
}
