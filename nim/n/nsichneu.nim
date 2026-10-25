const inputCount = csize_t(9)
const outputCount = csize_t(17)
const outputBytes = outputCount * 8
const maxRuns = 64'i64

proc nsichneu*(input: ptr UncheckedArray[int64], length: csize_t,
               output: ptr UncheckedArray[uint8], capacity: csize_t): int64
               {.cdecl, exportc: "nsichneu".} =
  if input.isNil or length != inputCount or input[0] < 1 or input[0] > maxRuns:
    return -1
  for index in 1 ..< int(length):
    if input[index] < -1000 or input[index] > 1000:
      return -1
  if output.isNil or capacity < outputBytes:
    return -2

  var p1: array[3, int64] = [input[1], input[2], input[3]]
  var p2: array[5, int64] = [input[4], input[5], input[6], input[7], input[8]]
  var p3: array[6, int64] = [0'i64, 0, 0, 0, 0, 0]
  var p1Count = 3'i64
  var p2Count = 5'i64
  var p3Count = 0'i64

  for run in 0 ..< input[0]:
    p1Count = 3
    p2Count = 5
    p3Count = 0
    for first in 0 ..< 3:
      for second in 0 ..< 3:
        if second == first:
          continue
        for third in 0 ..< 3:
          if third == first or third == second:
            continue
          if p1Count >= 3 and p3Count + 3 <= 6 and p1[second] == p1[third]:
            let x = p1[first]
            let y = p1[second]
            if x < y:
              p1Count -= 3
              p3[int(p3Count)] = x
              p3[int(p3Count + 1)] = y
              p3[int(p3Count + 2)] = x - y
              p3Count += 3

    for subsetNumber in 0 ..< 5:
      let omitted = 4 - subsetNumber
      var subset: array[4, int]
      var count = 0
      for index in 0 ..< 5:
        if index != omitted:
          subset[count] = index
          inc count
      for a in 0 ..< 4:
        for b in 0 ..< 4:
          if b == a:
            continue
          for c in 0 ..< 4:
            if c == a or c == b:
              continue
            for d in 0 ..< 4:
              if d == a or d == b or d == c:
                continue
              let i0 = subset[a]
              let i1 = subset[b]
              let i2 = subset[c]
              let i3 = subset[d]
              if p2Count >= 4 and p3Count + 3 <= 6 and p2[i1] == p2[i2] and p2[i1] == p2[i3]:
                let x = p2[i0]
                let y = p2[i1]
                if y > x:
                  p2Count -= 4
                  p3[int(p3Count)] = x
                  p3[int(p3Count + 1)] = y
                  p3[int(p3Count + 2)] = x + y
                  p3Count += 3

  var snapshot: array[17, int64]
  var position = 0
  snapshot[position] = p1Count
  inc position
  for index in 0 ..< 3:
    snapshot[position] = p1[index]
    inc position
  snapshot[position] = p2Count
  inc position
  for index in 0 ..< 5:
    snapshot[position] = p2[index]
    inc position
  snapshot[position] = p3Count
  inc position
  for index in 0 ..< 6:
    snapshot[position] = p3[index]
    inc position
  for index in 0 ..< int(outputCount):
    let bits = cast[uint64](snapshot[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 0xff)
  int64(outputBytes)
