## Independent Hopcroft partition-refinement draft; uncompiled and unrun.
import std/deques

proc enqueue(work: var Deque[int], queued: var seq[bool], id: int) =
  if not queued[id]:
    queued[id]=true
    work.addLast(id)

proc hopcroft_dfa_minimization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hopcroft_dfa_minimization".} =
  if input.isNil or length<2 or input[0]<1 or input[0]>4096 or input[1]<1 or input[1]>4: return -1
  let n=int(input[0]); let k=int(input[1])
  if length!=csize_t(2+n*(k+1)): return -1
  for s in 0 ..< n:
    if input[2+s]!=0 and input[2+s]!=1: return -1
  for i in 0 ..< n*k:
    if input[2+n+i]<0 or input[2+n+i]>=int64(n): return -1
  var head=newSeq[int](n*k); var next=newSeq[int](n*k)
  for i in 0 ..< n*k: head[i] = -1
  for state in 0 ..< n:
    for symbol in 0 ..< k:
      let edge=state*k+symbol
      let destination=int(input[2+n+edge])
      next[edge]=head[symbol*n+destination]
      head[symbol*n+destination]=edge
  var blocks=newSeq[seq[int]](2)
  for state in 0 ..< n: blocks[int(input[2+state])].add(state)
  if blocks[0].len==0:
    blocks[0]=blocks[1]
    blocks.setLen(1)
  elif blocks[1].len==0:
    blocks.setLen(1)
  var blockOf=newSeq[int](n); var position=newSeq[int](n)
  var retained=newSeq[int](n)
  for b in 0 ..< blocks.len:
    retained[b]=blocks[b].len
    for i,state in blocks[b]:
      blockOf[state]=b
      position[state]=i
  var work=initDeque[int]()
  var queued=newSeq[bool](n*k)
  for b in 0 ..< blocks.len:
    for symbol in 0 ..< k: enqueue(work,queued,b*k+symbol)
  var selected=newSeq[seq[int]](n)
  var touched: seq[int] = @[]
  while work.len>0:
    let id=work.popFirst()
    queued[id]=false
    let splitter=id div k; let symbol=id mod k
    touched.setLen(0)
    for destination in blocks[splitter]:
      var edge=head[symbol*n+destination]
      while edge>=0:
        let state=edge div k
        let b=blockOf[state]
        if selected[b].len==0: touched.add(b)
        selected[b].add(state)
        edge=next[edge]
    for b in touched:
      if selected[b].len==blocks[b].len:
        selected[b] = @[]
        continue
      let fresh=blocks.len
      blocks.add(@[])
      for state in selected[b]:
        let pos=position[state]
        let last=blocks[b][^1]
        blocks[b][pos]=last
        position[last]=pos
        blocks[b].setLen(blocks[b].len-1)
        position[state]=blocks[fresh].len
        blocks[fresh].add(state)
        blockOf[state]=fresh
      retained[fresh]=blocks[fresh].len
      if blocks[b].len*2<retained[b]:
        var compacted=newSeq[int](blocks[b].len)
        for i,state in blocks[b]: compacted[i]=state
        blocks[b]=compacted
        retained[b]=blocks[b].len
      selected[b] = @[]
      for symbol in 0 ..< k:
        if queued[b*k+symbol]: enqueue(work,queued,fresh*k+symbol)
        else:
          let smaller=if blocks[fresh].len<blocks[b].len: fresh else: b
          enqueue(work,queued,smaller*k+symbol)
  int64(blocks.len)
