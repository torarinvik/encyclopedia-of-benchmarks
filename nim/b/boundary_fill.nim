const MaxSide = 32
const MaxCells = MaxSide * MaxSide
const MaxInputLength = 6 + MaxCells

proc putI64(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[index * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc boundary_fill*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "boundary_fill".} =
  if input.isNil or int(length) < 6 or int(length) > MaxInputLength: return -1
  let widthValue = input[0]
  let heightValue = input[1]
  let startXValue = input[2]
  let startYValue = input[3]
  let newColor = input[4]
  let boundaryColor = input[5]
  if widthValue < 1 or widthValue > MaxSide or heightValue < 1 or heightValue > MaxSide: return -1
  if newColor < int64(low(int32)) or newColor > int64(high(int32)) or boundaryColor < int64(low(int32)) or boundaryColor > int64(high(int32)): return -1
  let width = int(widthValue)
  let height = int(heightValue)
  if int(length) != 6 + width * height or startXValue < 0 or startXValue >= widthValue or startYValue < 0 or startYValue >= heightValue: return -1
  let cells = width * height
  var image: array[MaxCells, int64]
  for index in 0 ..< cells:
    image[index] = input[6 + index]
    if image[index] < int64(low(int32)) or image[index] > int64(high(int32)): return -1
  let start = int(startXValue) * height + int(startYValue)
  if image[start] != newColor and image[start] != boundaryColor:
    var stack: array[MaxCells, int]
    var top = 0
    image[start] = newColor
    stack[top] = start
    inc top
    while top > 0:
      dec top
      let index = stack[top]
      let x = index div height
      let y = index mod height
      for dx in -1 .. 1:
        for dy in -1 .. 1:
          if dx == 0 and dy == 0: continue
          let nextX = x + dx
          let nextY = y + dy
          if nextX < 0 or nextX >= width or nextY < 0 or nextY >= height: continue
          let next = nextX * height + nextY
          if image[next] != newColor and image[next] != boundaryColor:
            image[next] = newColor
            stack[top] = next
            inc top
  let required = cells * 8
  if output.isNil or int(capacity) < required: return -2
  for index in 0 ..< cells: putI64(output, index, image[index])
  int64(required)
