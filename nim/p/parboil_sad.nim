const
  SadRange = 16
  SadDim = 33
  SadPositions = 1089
  SadPad = 1092
  SadSlots = 41 * SadPad
  TypeCounts: array[8, int] = [0, 1, 2, 2, 4, 8, 8, 16]
  TypeOffsets: array[8, int] = [0, 0, 1, 3, 5, 9, 17, 25]

proc pixel(input: ptr UncheckedArray[int64], image, y, x: int): int =
  let packed = uint32(input[image * 64 + y * 4 + x div 4])
  int((packed shr ((x mod 4) * 8)) and 255'u32)

proc parboil_sad*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "parboil_sad".} =
  if input.isNil or length != csize_t(128): return -1
  for i in 0 ..< 128:
    if input[i] < 0 or input[i] > 4_294_967_295'i64: return -1

  var sads: array[SadSlots, uint16]
  for py in -SadRange .. SadRange:
    for px in -SadRange .. SadRange:
      for by in 0 ..< 4:
        for bx in 0 ..< 4:
          let base = (TypeOffsets[7] + by * 4 + bx) * SadPad
          let pos = (py + SadRange) * SadDim + px + SadRange
          var sad = 0'u32
          for y in 0 ..< 4:
            for x in 0 ..< 4:
              let fy = by * 4 + y
              let fx = bx * 4 + x
              let ry = min(15, max(0, fy + py))
              let rx = min(15, max(0, fx + px))
              let delta = pixel(input, 0, fy, fx) - pixel(input, 1, ry, rx)
              sad += uint32(if delta < 0: -delta else: delta)
          sads[base + pos] = uint16(sad)

  # Preserve larger_sads' type-6, type-5, type-4, type-3, type-2, type-1 order.
  for by in 0 ..< 2:
    for bx in 0 ..< 4:
      let dst = TypeOffsets[6] + 4 * by + bx
      let src = TypeOffsets[7] + 8 * by + bx
      for p in 0 ..< SadPositions:
        sads[dst * SadPad + p] = uint16(uint32(sads[src * SadPad + p]) + uint32(sads[(src + 4) * SadPad + p]))
  for by in 0 ..< 4:
    for bx in 0 ..< 2:
      let dst = TypeOffsets[5] + 2 * by + bx
      let src = TypeOffsets[7] + 4 * by + 2 * bx
      for p in 0 ..< SadPositions:
        sads[dst * SadPad + p] = uint16(uint32(sads[src * SadPad + p]) + uint32(sads[(src + 1) * SadPad + p]))
  for by in 0 ..< 2:
    for bx in 0 ..< 2:
      let dst = TypeOffsets[4] + 2 * by + bx
      let src = TypeOffsets[5] + 4 * by + bx
      for p in 0 ..< SadPositions:
        sads[dst * SadPad + p] = uint16(uint32(sads[src * SadPad + p]) + uint32(sads[(src + 2) * SadPad + p]))
  for bx in 0 ..< 2:
    let dst = TypeOffsets[3] + bx
    let src = TypeOffsets[4] + bx
    for p in 0 ..< SadPositions:
      sads[dst * SadPad + p] = uint16(uint32(sads[src * SadPad + p]) + uint32(sads[(src + 2) * SadPad + p]))
  for by in 0 ..< 2:
    let dst = TypeOffsets[2] + by
    let src = TypeOffsets[4] + 2 * by
    for p in 0 ..< SadPositions:
      sads[dst * SadPad + p] = uint16(uint32(sads[src * SadPad + p]) + uint32(sads[(src + 1) * SadPad + p]))
  for p in 0 ..< SadPositions:
    sads[TypeOffsets[1] * SadPad + p] = uint16(uint32(sads[TypeOffsets[2] * SadPad + p]) + uint32(sads[(TypeOffsets[2] + 1) * SadPad + p]))

  var checksum = 0'i64
  for kind in 1 .. 7:
    for block in 0 ..< TypeCounts[kind]:
      for p in 0 ..< SadPositions:
        checksum += int64(sads[(TypeOffsets[kind] + block) * SadPad + p])
  checksum
