const MaxK = 16
const MaxQ = 16
const MaxNodes = 31
const MaxOut = 174
type Node = object
  bit, left, right, key, low, high, leaves: int
proc build(lo, hi, width: int, keys: array[MaxK,uint32], nodes: var array[MaxNodes,Node], used: var int): int =
  result = used; inc used
  if hi-lo == 1:
    nodes[result] = Node(bit: -1, left: -1, right: -1, key: int(keys[lo]), low: int(keys[lo]), high: int(keys[lo]), leaves: 1)
    return
  let diff = keys[lo] xor keys[hi-1]
  var bit = 0
  while ((diff shr (width-1-bit)) and 1) == 0: inc bit
  var split = lo
  while split < hi and ((keys[split] shr (width-1-bit)) and 1) == 0: inc split
  let left = build(lo, split, width, keys, nodes, used)
  let right = build(split, hi, width, keys, nodes, used)
  nodes[result] = Node(bit: bit, left: left, right: right, key: -1, low: int(keys[lo]), high: int(keys[hi-1]), leaves: nodes[left].leaves + nodes[right].leaves)
proc rankKey(query: uint32, width: int, nodes: array[MaxNodes,Node]): int =
  var id = 0
  while true:
    let node = nodes[id]
    if query < uint32(node.low): return result
    if query > uint32(node.high): return result + node.leaves
    if node.bit < 0: return result
    if ((query shr (width-1-node.bit)) and 1) == 1:
      result += nodes[node.left].leaves; id = node.right
    else: id = node.left
proc putI64(outp: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: outp[pos+b] = uint8((bits shr (8*b)) and 255)
proc mmpfhCompactedTrieRank(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                            {.cdecl, exportc: "mmpfh_compacted_trie_rank".} =
  if input.isNil or length < 3 or length > 35: return -1
  let w0=input[0];let d0=input[1];let q0=input[2]
  if w0<1 or w0>16 or d0<1 or d0>16 or q0<1 or q0>16 or length != csize_t(3+d0+q0): return -1
  let limit=1'u32 shl int(w0)
  var keys: array[MaxK,uint32]
  for i in 0..<int(d0):
    let x=input[3+i]
    if x<0 or uint64(x)>=uint64(limit) or (i>0 and x<=input[2+i]): return -1
    keys[i]=uint32(x)
  for i in 0..<int(q0):
    let x=input[3+int(d0)+i]
    if x<0 or uint64(x)>=uint64(limit): return -1
  var nodes: array[MaxNodes,Node];var nodeUsed=0
  discard build(0,int(d0),int(w0),keys,nodes,nodeUsed)
  var staged: array[MaxOut,int64];var used=0
  staged[used]=d0;inc used;staged[used]=nodeUsed;inc used;staged[used]=q0;inc used
  for i in 0..<nodeUsed:
    staged[used]=nodes[i].bit;inc used;staged[used]=nodes[i].left;inc used;staged[used]=nodes[i].right;inc used
    staged[used]=nodes[i].low;inc used;staged[used]=nodes[i].high;inc used
  for i in 0..<int(q0): staged[used]=rankKey(uint32(input[3+int(d0)+i]),int(w0),nodes);inc used
  let required=used*8
  if output.isNil or capacity<csize_t(required):return -2
  for i in 0..<used:putI64(output,i*8,staged[i])
  int64(required)
