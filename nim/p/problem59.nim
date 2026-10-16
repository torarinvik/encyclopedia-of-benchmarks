const MaxCipher=4096
const KeyCount=17576
proc allowed(value:int64):bool=(value in 9'i64..13'i64) or (value in 32'i64..126'i64)
proc word(id:int):string = ["the","be","to","of","and","in","that","have"][id]
proc containsWord(input:ptr UncheckedArray[int64],length:int,keys:var array[KeyCount,array[3,uint8]],index:int,w:string):bool=
 if length<w.len:return false
 for start in 0..(length-w.len):
  var matched=true
  for j in 0..<w.len:
   let pos=start+j
   var ch=uint8(input[pos]) xor keys[index][pos mod 3]
   if ch>=65 and ch<=90: ch+=32
   if ch!=uint8(ord(w[j])):matched=false;break
  if matched:return true
 false
proc problem59*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"problem59".}=
 if input==nil or length==0 or length>MaxCipher.csize_t:return -1
 for i in 0..<length.int:if input[i]<0 or input[i]>255:return -1
 var keys:array[KeyCount,array[3,uint8]]
 var count=0
 for a in 97..122:
  for b in 97..122:
   for c in 97..122:
    var valid=true
    for i in 0..<length.int:
     let k=if i mod 3==0:a elif i mod 3==1:b else:c
     if not allowed(input[i] xor int64(k)):valid=false;break
    if valid:keys[count]=[uint8(a),uint8(b),uint8(c)];inc count
 for id in 0..7:
  var kept=0
  for i in 0..<count:
   if containsWord(input,length.int,keys,i,word(id)):
    keys[kept]=keys[i];inc kept
  count=kept
  if count==1:break
 if count==0:return -1
 var total=0'i64
 for i in 0..<length.int:total+=input[i] xor int64(keys[0][i mod 3])
 total
