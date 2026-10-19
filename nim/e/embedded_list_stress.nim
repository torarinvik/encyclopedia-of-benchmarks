# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
# Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const MaxItems = 32
type Node = object
  data: uint16
  idx: int32
  next: int

proc crcByte(valueIn: uint16, crcIn: uint16): uint16 =
  var value=valueIn; var crc=crcIn
  for bit in 0 ..< 8:
    let mix=(value and 1) xor (crc and 1)
    value=value shr 1
    if mix != 0: crc=crc xor 0x4002'u16
    crc=crc shr 1
    if mix != 0: crc=crc or 0x8000'u16 else: crc=crc and 0x7fff'u16
  crc
proc crc16(value: uint16, crc: uint16): uint16 = crcByte(value shr 8, crcByte(value and 255, crc))
proc compare(a: var array[MaxItems+2,Node], x,y: int, complex: bool, seed: uint16): int =
  if complex:
    if (a[x].data and 0x80) == 0: a[x].data=(a[x].data and 0xff00) or 0x80 or ((a[x].data xor (a[x].data shr 8) xor seed) and 0x7f)
    if (a[y].data and 0x80) == 0: a[y].data=(a[y].data and 0xff00) or 0x80 or ((a[y].data xor (a[y].data shr 8) xor seed) and 0x7f)
    return int(a[x].data and 127)-int(a[y].data and 127)
  a[x].data=(a[x].data and 0xff00) or ((a[x].data shr 8) and 255)
  a[y].data=(a[y].data and 0xff00) or ((a[y].data shr 8) and 255)
  int(a[x].idx-a[y].idx)
proc sortList(a: var array[MaxItems+2,Node], headIn: int, complex: bool, seed: uint16): int =
  var head=headIn; var width=1
  while true:
    var p=head; var newHead = -1; var tail = -1; var merges=0
    while p >= 0:
      inc merges
      var q=p; var psize=0
      for i in 0 ..< width:
        inc psize; q=a[q].next
        if q < 0: break
      var qsize=width
      while psize>0 or (qsize>0 and q>=0):
        var e: int
        if psize==0: e=q; q=a[q].next; dec qsize
        elif qsize==0 or q<0: e=p; p=a[p].next; dec psize
        elif compare(a,p,q,complex,seed)<=0: e=p; p=a[p].next; dec psize
        else: e=q; q=a[q].next; dec qsize
        if tail>=0: a[tail].next=e else: newHead=e
        tail=e
      p=q
    a[tail].next = -1; head=newHead
    if merges<=1: return head
    width*=2
proc findNode(a: array[MaxItems+2,Node], headIn, idx, data: int): int =
  var p=headIn
  while p>=0:
    if (if idx>=0: int(a[p].idx)==idx else: int(a[p].data and 255)==data): return p
    p=a[p].next
  -1
proc reverse(a: var array[MaxItems+2,Node], head: var int) =
  var prev = -1; var cur=head
  while cur>=0:
    let next=a[cur].next; a[cur].next=prev; prev=cur; cur=next
  head=prev

proc embedded_list_stress*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,exportc:"embedded_list_stress".} =
  if input==nil or length!=4:return -1
  let rn=input[0];let seed=input[1];let findCount=input[2];let mode=input[3]
  if rn<4 or rn>MaxItems or seed<1 or seed>255 or findCount<0 or findCount>32 or (mode != -1 and mode != 1):return -1
  let n=int(rn);let tail=n+1;var a:array[MaxItems+2,Node]
  a[0]=Node(data:0x8080,idx:0,next:1);a[tail]=Node(data:0xffff,idx:0x7fff,next:-1)
  for i in 0..<n:
    let dat=uint16((((seed xor int64(i)) and 15) shl 3) or int64(i and 7))
    a[i+1]=Node(data:(dat shl 8) or dat,idx:0,next:i+2)
  a[n].next=tail
  var idx=1;var p=a[0].next
  while p!=tail:
    if idx<n div 5:a[p].idx=int32(idx);inc idx
    else:let pat=idx xor int(seed);inc idx;a[p].idx=int32((((idx and 7) shl 8) or pat) and 0x3fff)
    p=a[p].next
  var head=sortList(a,0,false,uint16(seed));var infoIdx=int(mode);var infoData=0;var result=0'u16;var found=0'u32;var missed=0'u32
  for k in 0..<int(findCount):
    infoData=k and 255;let got=findNode(a,head,infoIdx,infoData);reverse(a,head)
    if got<0:inc missed;let first=a[head].next;if first>=0:result=result+((a[first].data shr 8) and 1)
    else:inc found;if (a[got].data and 1)!=0:result=result+((a[got].data shr 9) and 1);let next=a[got].next;if next>=0:a[got].next=a[next].next;a[next].next=a[head].next;a[head].next=next
    if infoIdx>=0:inc infoIdx
  result=result+uint16(found*4-missed)
  if mode>0:head=sortList(a,head,true,uint16(seed))
  let at=a[head].next
  if at>=0:
    let rem=a[at].next;swap(a[at].data,a[rem].data);swap(a[at].idx,a[rem].idx);a[at].next=a[rem].next;a[rem].next = -1
    var f=findNode(a,head,infoIdx,infoData);if f<0:f=a[head].next
    while f>=0:result=crc16(a[head].data,result);f=a[f].next
    swap(a[rem].data,a[at].data);swap(a[rem].idx,a[at].idx);a[rem].next=a[at].next;a[at].next=rem
  head=sortList(a,head,false,uint16(seed));var f=a[head].next
  while f>=0:result=crc16(a[head].data,result);f=a[f].next
  if output==nil or capacity<2:return -2
  output[0]=uint8(result and 255);output[1]=uint8(result shr 8);2
