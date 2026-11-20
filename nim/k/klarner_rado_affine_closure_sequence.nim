const
  MaxIndex = 64'i64
  MaxParseableLength = 2

proc klarner_rado_affine_closure_sequence*(input: ptr UncheckedArray[int64],
                                            length: csize_t): int64
    {.cdecl, exportc: "klarner_rado_affine_closure_sequence".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let requested = input[0]
  if length != 1 or requested < 1 or requested > MaxIndex: return -1

  var terms: array[64, int64]
  terms[0] = 1
  var count = 1
  var twice = 0
  var thricePlusTwo = 0
  var sixfoldPlusThree = 0
  while count < int(requested):
    let byTwo = 2 * terms[twice]
    let byThree = 3 * terms[thricePlusTwo] + 2
    let bySix = 6 * terms[sixfoldPlusThree] + 3
    let next = min(byTwo, min(byThree, bySix))
    terms[count] = next
    inc count
    if byTwo == next: inc twice
    if byThree == next: inc thricePlusTwo
    if bySix == next: inc sixfoldPlusThree
  terms[int(requested) - 1]
