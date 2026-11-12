const MaxStates = 256
const Modulus = 998_244_353'i64

proc broken_profile_domino_tilings*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "broken_profile_domino_tilings".} =
  if input == nil or length != 2: return -1
  let h0 = input[0]; let w0 = input[1]
  if h0 < 1 or h0 > 64 or w0 < 1 or w0 > 64 or min(h0, w0) > 8 or h0 * w0 > 512: return -1
  let height = int(max(h0, w0)); let width = int(min(h0, w0))
  let states = 1 shl width; let full = states - 1
  var dp, next: array[MaxStates, int64]
  dp[0] = 1
  for row in 0 ..< height:
    for s in 0 ..< states: next[s] = 0
    for incoming in 0 ..< states:
      if dp[incoming] != 0:
        for outgoing in 0 ..< states:
          if (incoming and outgoing) != 0 or (row + 1 == height and outgoing != 0): continue
          let freeCells = full and not (incoming or outgoing)
          var col = 0; var valid = true
          while col < width:
            if (freeCells and (1 shl col)) != 0:
              if col + 1 >= width or (freeCells and (1 shl (col + 1))) == 0:
                valid = false; break
              col += 2
            else: inc col
          if valid: next[outgoing] = (next[outgoing] + dp[incoming]) mod Modulus
    dp = next
  dp[0]
