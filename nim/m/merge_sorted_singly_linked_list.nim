const MaxNodes = 128
const MaxInputLength = 130
const MaxOutputBytes = 12 * MaxNodes

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  ListNode = object
    value: int32
    next: int32
    origin: int32
    position: int32

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc merge_sorted_singly_linked_list*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "merge_sorted_singly_linked_list".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxNodes): return -1
  let lenA = int(input[0])
  if lenA > int(length) - 2: return -1
  let lenBPos = 1 + lenA
  let rawLenB = input[lenBPos]
  if rawLenB < 0 or rawLenB > int64(MaxNodes - lenA): return -1
  let lenB = int(rawLenB)
  let total = lenA + lenB
  if int(length) != 2 + total: return -1

  var nodes: array[MaxNodes, ListNode]
  for i in 0 ..< lenA:
    let raw = input[1 + i]
    if raw < int64(low(int32)) or raw > int64(high(int32)) or (i > 0 and input[i] > raw): return -1
    nodes[i] = ListNode(value: int32(raw), next: (if i + 1 < lenA: int32(i + 1) else: -1), origin: 0, position: int32(i))
  let bStart = lenBPos + 1
  for i in 0 ..< lenB:
    let raw = input[bStart + i]
    if raw < int64(low(int32)) or raw > int64(high(int32)) or (i > 0 and input[bStart + i - 1] > raw): return -1
    let node = lenA + i
    nodes[node] = ListNode(value: int32(raw), next: (if i + 1 < lenB: int32(node + 1) else: -1), origin: 1, position: int32(i))

  var headA = (if lenA == 0: -1'i32 else: 0'i32)
  var headB = (if lenB == 0: -1'i32 else: int32(lenA))
  var mergedHead = -1'i32
  var tail = -1'i32
  while headA >= 0 and headB >= 0:
    var node: int32
    if nodes[int(headA)].value <= nodes[int(headB)].value:
      node = headA
      headA = nodes[int(node)].next
    else:
      node = headB
      headB = nodes[int(node)].next
    if tail < 0: mergedHead = node
    else: nodes[int(tail)].next = node
    tail = node
  let remainder = (if headA >= 0: headA else: headB)
  if tail < 0: mergedHead = remainder
  else: nodes[int(tail)].next = remainder

  let outputBytes = 12 * total
  if output == nil or capacity < csize_t(outputBytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  var written = 0
  var node = mergedHead
  while node >= 0:
    let item = nodes[int(node)]
    putI32Le(cast[U8Output](addr buffer[0]), written, item.value)
    putI32Le(cast[U8Output](addr buffer[0]), written + 4, item.origin)
    putI32Le(cast[U8Output](addr buffer[0]), written + 8, item.position)
    written += 12
    node = item.next
  for i in 0 ..< outputBytes: output[i] = buffer[i]
  int64(outputBytes)
