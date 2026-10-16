proc word_ladder*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "word_ladder".} =
  if input == nil or length < 4: return -1
  let widthValue=input[0];let begin=input[1];let ending=input[2];let countValue=input[3]
  if widthValue<1 or widthValue>5 or countValue<0 or countValue>32:return -1
  let width=int(widthValue);let count=int(countValue)
  if int(length)!=4+count:return -1
  var limit=1'i64
  for _ in 0..<width:limit*=26
  if begin<0 or begin>=limit or ending<0 or ending>=limit:return -1
  var dict:array[32,int64];var hasEnd=false
  for i in 0..<count:
    let code=input[4+i]
    if code<0 or code>=limit:return -1
    dict[i]=code
    if code==ending:hasEnd=true
  if output==nil or capacity<8:return -2
  var answer=0'i64
  if hasEnd:
    var queue:array[33,int64];var dist:array[33,int64];var head=0;var tail=1
    queue[0]=begin;dist[0]=1
    while head<tail and answer==0:
      let word=queue[head];let depth=dist[head];inc head
      var place=1'i64
      for _ in 0..<width:
        if answer!=0:break
        let digit=(word div place) mod 26
        for letter in 0'i64..<26:
          if letter==digit:continue
          let next=word+(letter-digit)*place
          if next==ending:answer=depth+1;break
          var inDict=false
          for j in 0..<count:
            if dict[j]==next:inDict=true;break
          var seen=false
          for j in 1..<tail:
            if queue[j]==next:seen=true;break
          if inDict and not seen and tail<33:
            queue[tail]=next;dist[tail]=depth+1;inc tail
        place*=26
  let bits=cast[uint64](answer)
  for b in 0..<8:output[b]=uint8((bits shr (8*b)) and 255)
  return 8
