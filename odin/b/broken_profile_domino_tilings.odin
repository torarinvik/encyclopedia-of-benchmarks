package broken_profile_domino_tilings

MAX_STATES :: 256
MODULUS :: i64(998244353)

broken_profile_domino_tilings :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	h0, w0 := input[0], input[1]
	if h0 < 1 || h0 > 64 || w0 < 1 || w0 > 64 || min(h0,w0) > 8 || h0*w0 > 512 do return -1
	height, width := int(max(h0,w0)), int(min(h0,w0))
	states := 1 << width; full := states-1
	dp, next: [MAX_STATES]i64 = {}, {}; dp[0] = 1
	for row := 0; row < height; row += 1 {
		for s := 0; s < states; s += 1 { next[s] = 0 }
		for incoming := 0; incoming < states; incoming += 1 {
			if dp[incoming] != 0 {
				for outgoing := 0; outgoing < states; outgoing += 1 {
					if (incoming & outgoing) != 0 || (row+1 == height && outgoing != 0) do continue
					free := full & ~(incoming | outgoing); col := 0; valid := true
					for col < width {
						if (free & (1 << col)) != 0 {
							if col+1 >= width || (free & (1 << (col+1))) == 0 { valid = false; break }
							col += 2
						} else { col += 1 }
					}
					if valid { next[outgoing] = (next[outgoing]+dp[incoming])%MODULUS }
				}
			}
		}
		dp = next
	}
	return dp[0]
}
