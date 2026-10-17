const MaxInputLength = 98
const MaxOutputFields = 594
const MinValue = -1_000_000'i64
const MaxValue = 1_000_000'i64

proc append(records: ptr UncheckedArray[int64], count: var int, value: int64) =
  records[count] = value
  inc count

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc table_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "table_list".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > 32 or int64(length) != 1 + 3 * operationCount: return -1
  var items: array[64, int64]
  var records: array[MaxOutputFields, int64]
  var head = 32
  var itemCount = 0
  var recordCount = 0
  var cursor = 1
  for _ in 0 ..< int(operationCount):
    let opcode = input[cursor]
    let arg1 = input[cursor + 1]
    let arg2 = input[cursor + 2]
    cursor += 3
    case opcode
    of 0, 1:
      if arg1 < MinValue or arg1 > MaxValue or arg2 != 0 or itemCount >= 32: return -1
      if opcode == 0:
        dec head
        items[head] = arg1
      else:
        items[head + itemCount] = arg1
      inc itemCount
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, 0)
    of 2:
      if arg1 != 0 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      if itemCount == 0: append(addr records[0], recordCount, 0)
      else:
        append(addr records[0], recordCount, 1)
        append(addr records[0], recordCount, items[head])
        inc head
        dec itemCount
    of 3:
      if arg1 != 0 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      if itemCount == 0: append(addr records[0], recordCount, 0)
      else:
        append(addr records[0], recordCount, 1)
        dec itemCount
        append(addr records[0], recordCount, items[head + itemCount])
    of 4, 5:
      if arg1 != 0 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      if itemCount == 0: append(addr records[0], recordCount, 0)
      else:
        append(addr records[0], recordCount, 1)
        append(addr records[0], recordCount, if opcode == 4: items[head] else: items[head + itemCount - 1])
    of 6:
      if arg2 != 0 or arg1 < 1 or arg1 > int64(itemCount): return -1
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, 1)
      append(addr records[0], recordCount, items[head + int(arg1) - 1])
    of 7:
      if arg1 < 1 or arg1 > int64(itemCount) or arg2 < MinValue or arg2 > MaxValue: return -1
      items[head + int(arg1) - 1] = arg2
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, 0)
    of 8:
      if arg1 < -1 or arg1 > 33 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, 1)
      append(addr records[0], recordCount, if arg1 >= 1 and arg1 <= int64(itemCount): 1'i64 else: 0'i64)
    of 9:
      if arg1 != 0 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, 1)
      append(addr records[0], recordCount, int64(itemCount))
    of 10, 11:
      if arg1 != 0 or arg2 != 0: return -1
      append(addr records[0], recordCount, opcode)
      append(addr records[0], recordCount, int64(itemCount))
      for offset in 0 ..< itemCount:
        let logical = if opcode == 10: offset + 1 else: itemCount - offset
        append(addr records[0], recordCount, int64(logical))
        append(addr records[0], recordCount, items[head + logical - 1])
    else:
      return -1
  append(addr records[0], recordCount, 12)
  append(addr records[0], recordCount, int64(itemCount))
  for offset in 0 ..< itemCount: append(addr records[0], recordCount, items[head + offset])
  let outputBytes = recordCount * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< recordCount: writeI64Le(output, index * 8, records[index])
  int64(outputBytes)
