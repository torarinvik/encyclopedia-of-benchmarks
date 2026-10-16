proc uncommon_words*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "uncommon_words".} =
  if values == nil or length < 1 or length > 1089 or values[0] < 0 or values[0] > 64: return -1
  var words: array[64,array[16,uint8]];var lens: array[64,int];var counts: array[64,int];var distinct=0;var pos=1
  for _ in 0 ..< int(values[0]):
    if pos>=int(length) or values[pos]<1 or values[pos]>16:return -1
    let size=int(values[pos]);inc pos;if size>int(length)-pos:return -1
    for j in 0..<size:if values[pos+j]<97 or values[pos+j]>122:return -1
    var id=0
    while id<distinct:
      if lens[id]==size:
        var j=0
        while j<size and int64(words[id][j])==values[pos+j]:inc j
        if j==size:break
      inc id
    if id==distinct:lens[id]=size;for j in 0..<size:words[id][j]=uint8(values[pos+j]);inc distinct
    inc counts[id];pos+=size
  if pos!=int(length):return -1
  var temp:array[1089,uint8];var at=0
  for id in 0..<distinct:
    if counts[id]==1:
      for j in 0..<lens[id]:temp[at+j]=words[id][j]
      at+=lens[id];temp[at]=10;inc at
  if at>0:dec at
  temp[at]=0;inc at
  if output==nil or int(capacity)<at:return -2
  for i in 0..<at:output[i]=temp[i]
  int64(at)
