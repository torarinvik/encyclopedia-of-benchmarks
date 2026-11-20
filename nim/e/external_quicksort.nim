## Fixed-size sorted endpoint buffer quicksort.
const MaxLength = 1024
const BufferSize = 8

proc sortBuffer(buffer: var array[BufferSize, int64], length: int) =
  for i in 1 ..< length:
    let value = buffer[i]
    var position = i
    while position > 0 and value < buffer[position - 1]:
      buffer[position] = buffer[position - 1]
      dec position
    buffer[position] = value

proc sortRange(values: ptr UncheckedArray[int64], firstArg, lastArg: int) =
  var first = firstArg
  var last = lastArg
  while last > first:
    var readLow = first
    var writeLow = first
    var readHigh = last
    var writeHigh = last
    var buffer: array[BufferSize, int64]
    var buffered = 0
    var haveMaxLower = false
    var haveMinUpper = false
    var maxLower = 0'i64
    var minUpper = 0'i64
    var lowerWrittenBound = first - 1
    var upperWrittenBound = last + 1

    while readHigh >= readLow:
      var incoming: int64
      if readLow - writeLow < writeHigh - readHigh:
        incoming = values[readLow]
        inc readLow
      else:
        incoming = values[readHigh]
        dec readHigh

      if buffered < BufferSize:
        buffer[buffered] = incoming
        inc buffered
        sortBuffer(buffer, buffered)
      elif incoming > buffer[BufferSize - 1]:
        if haveMinUpper and incoming > minUpper:
          upperWrittenBound = writeHigh
        else:
          minUpper = incoming
          haveMinUpper = true
        values[writeHigh] = incoming
        dec writeHigh
      elif incoming < buffer[0]:
        if haveMaxLower and incoming < maxLower:
          lowerWrittenBound = writeLow
        else:
          maxLower = incoming
          haveMaxLower = true
        values[writeLow] = incoming
        inc writeLow
      elif writeLow - first < last - writeHigh:
        let outgoing = buffer[0]
        values[writeLow] = outgoing
        inc writeLow
        maxLower = outgoing
        haveMaxLower = true
        buffer[0] = incoming
        sortBuffer(buffer, BufferSize)
      else:
        let outgoing = buffer[BufferSize - 1]
        values[writeHigh] = outgoing
        dec writeHigh
        minUpper = outgoing
        haveMinUpper = true
        buffer[BufferSize - 1] = incoming
        sortBuffer(buffer, BufferSize)

    while buffered > 0:
      dec buffered
      values[writeHigh] = buffer[buffered]
      dec writeHigh

    if lowerWrittenBound - first < last - upperWrittenBound:
      sortRange(values, first, lowerWrittenBound)
      first = upperWrittenBound
    else:
      sortRange(values, upperWrittenBound, last)
      last = lowerWrittenBound

proc external_quicksort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "external_quicksort".} =
  if length == 0 or length > csize_t(MaxLength) or values == nil: return
  sortRange(values, 0, int(length) - 1)
