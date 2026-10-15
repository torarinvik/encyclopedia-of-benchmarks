proc max_product_of_three*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_product_of_three".} =
  const invalid = low(int64)
  if input.isNil or length < 1 or input[0] < 3 or input[0] > 128 or length != csize_t(input[0] + 1): return invalid
  let n = int(input[0])
  for i in 0 ..< n:
    if input[i + 1] < -1000 or input[i + 1] > 1000: return invalid
  var max1 = input[1]; var max2 = -1001'i64; var max3 = -1001'i64
  var min1 = input[1]; var min2 = 1001'i64
  for i in 1 ..< n:
    let value = input[i + 1]
    if value > max1: max3 = max2; max2 = max1; max1 = value
    elif value > max2: max3 = max2; max2 = value
    elif value > max3: max3 = value
    if value < min1: min2 = min1; min1 = value
    elif value < min2: min2 = value
  let product1 = max1 * max2 * max3
  let product2 = max1 * min1 * min2
  max(product1, product2)
