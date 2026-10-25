## Copyright (C) 1996 McGill University.
## Copyright (C) 1996 McCAT System Group.
## Copyright (C) 1996 ACAPS Benchmark Administrator
##                    benadmin@acaps.cs.mcgill.ca
##
## This program is free software; you can redistribute it and/or modify
## it provided this copyright notice is maintained.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

const MaxNodes = 64
const QueryCount = 100
const OutputBytes = 33

type TreeNode = object
  value: int32
  left: int32
  right: int32

proc treeSize(tree: var array[MaxNodes, TreeNode], node: int32): int32 =
  if node < 0: return 0
  1 + treeSize(tree, tree[int(node)].left) + treeSize(tree, tree[int(node)].right)

proc treeSum(tree: var array[MaxNodes, TreeNode], node: int32): float64 =
  if node < 0: return 0.0
  float64(tree[int(node)].value) + treeSum(tree, tree[int(node)].left) + treeSum(tree, tree[int(node)].right)

proc memberDfs(tree: var array[MaxNodes, TreeNode], node: int32, sought: int32): bool =
  if node < 0: return false
  if tree[int(node)].value == sought: return true
  if memberDfs(tree, tree[int(node)].left, sought): return true
  memberDfs(tree, tree[int(node)].right, sought)

proc putU32Le(output: ptr UncheckedArray[uint8], offset: int, value: uint32) =
  for i in 0 ..< 4: output[offset + i] = uint8((value shr (8 * i)) and 255)

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  var bits = cast[uint64](value)
  for i in 0 ..< 8:
    output[offset + i] = uint8(bits and 255)
    bits = bits shr 8

proc mccat_bintr*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mccat_bintr".} =
  if input.isNil or inputLength < 103 or inputLength > csize_t(MaxNodes + 102): return -1
  let nodeCountValue = input[0]
  if nodeCountValue < 1 or nodeCountValue > int64(MaxNodes): return -1
  let nodeCount = int(nodeCountValue)
  if inputLength != csize_t(nodeCount) + csize_t(102) or input[nodeCount + 1] != int64(QueryCount): return -1
  for i in 0 ..< nodeCount:
    if input[i + 1] == 0 or input[i + 1] < -32768 or input[i + 1] > 32767: return -1
  for i in 0 ..< QueryCount:
    let value = input[nodeCount + 2 + i]
    if value == 0 or value < -32768 or value > 32767: return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2

  var tree: array[MaxNodes, TreeNode]
  var root = -1'i32
  var used = 0'i32
  for i in 0 ..< nodeCount:
    let value = int32(input[i + 1])
    if root < 0:
      root = 0
      tree[0] = TreeNode(value: value, left: -1, right: -1)
      used = 1
      continue
    var current = root
    while true:
      let slot = int(current)
      if value == tree[slot].value: break
      if value < tree[slot].value:
        if tree[slot].left < 0:
          tree[slot].left = used
          tree[int(used)] = TreeNode(value: value, left: -1, right: -1)
          inc used
          break
        current = tree[slot].left
      else:
        if tree[slot].right < 0:
          tree[slot].right = used
          tree[int(used)] = TreeNode(value: value, left: -1, right: -1)
          inc used
          break
        current = tree[slot].right

  let size = treeSize(tree, root)
  let sum = treeSum(tree, root)
  let mean = sum / float64(size)
  for i in 0 ..< OutputBytes: output[i] = 0
  putU32Le(output, 0, uint32(size))
  putF64Le(output, 4, sum)
  putF64Le(output, 12, mean)
  for i in 0 ..< QueryCount:
    if memberDfs(tree, root, int32(input[nodeCount + 2 + i])):
      output[20 + i div 8] = output[20 + i div 8] or uint8(1 shl (i mod 8))
  OutputBytes
