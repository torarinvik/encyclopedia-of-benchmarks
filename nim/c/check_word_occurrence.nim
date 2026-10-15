const MaxInput=1024
const MaxEntries=1025
proc ws(c:uint8):bool=(c>=9 and c<=13) or c==32
proc lowerAscii(c:uint8):uint8=if c>=65 and c<=90:uint8(c+32) else:c
proc forbidden(text:array[MaxInput,uint8],start,n:int):bool=
  const names=["constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"]
  for name in names:
    if n==name.len:
      var i=0
      while i<n and lowerAscii(text[start+i])==uint8(ord(name[i])):inc i
      if i==n:return true
  false
proc put32(outp:ptr UncheckedArray[uint8],pos:var int,x:uint32)=
  var bits=x
  for i in 0..<4:outp[pos]=uint8(bits and 255);inc pos;bits=bits shr 8
proc check_word_occurrence*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"check_word_occurrence".}=
  if input.isNil or length<2 or input[0]<0 or input[0]>1 or input[1]<0 or input[1]>MaxInput or length!=csize_t(input[1]+2):return -1
  let n=int(input[1]);var text:array[MaxInput,uint8]
  for i in 0..<n:
    let v=input[i+2];if v<0 or v>127:return -1
    let c=uint8(v);if not ((c>=65 and c<=90) or (c>=97 and c<=122) or ws(c)):return -1
    text[i]=if input[0]==1:lowerAscii(c) else:c
  var starts:array[MaxEntries,int];var lens:array[MaxEntries,int];var counts:array[MaxEntries,uint32]
  var entries=0;var i=0;var start=0
  while true:
    if i==n or ws(text[i]):
      let size=i-start;if forbidden(text,start,size):return -1
      var j=0
      while j<entries:
        if lens[j]==size:
          var q=0;while q<size and text[starts[j]+q]==text[start+q]:inc q
          if q==size:break
        inc j
      if j==entries:starts[j]=start;lens[j]=size;inc entries
      inc counts[j]
      if i==n:break
      while i<n and ws(text[i]):inc i
      start=i
    else:inc i
  var need=4;for j in 0..<entries:need+=8+lens[j]
  if capacity<csize_t(need) or output.isNil:return -2
  var pos=0;put32(output,pos,uint32(entries))
  for j in 0..<entries:
    put32(output,pos,uint32(lens[j]));for q in 0..<lens[j]:output[pos]=text[starts[j]+q];inc pos
    put32(output,pos,counts[j])
  int64(pos)
