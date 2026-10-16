const MAX_INPUT_LENGTH=512
const MAX_OUTPUT_BYTES=512
proc morseWord(index: int): int64 =
  if index == 0: return 514'i64
  if index == 1: return 1031'i64
  if index == 2: return 1029'i64
  if index == 3: return 771'i64
  if index == 4: return 257'i64
  if index == 5: return 1037'i64
  if index == 6: return 769'i64
  if index == 7: return 1039'i64
  if index == 8: return 515'i64
  if index == 9: return 1032'i64
  if index == 10: return 770'i64
  if index == 11: return 1035'i64
  if index == 12: return 512'i64
  if index == 13: return 513'i64
  if index == 14: return 768'i64
  if index == 15: return 1033'i64
  if index == 16: return 1026'i64
  if index == 17: return 773'i64
  if index == 18: return 775'i64
  if index == 19: return 256'i64
  if index == 20: return 774'i64
  if index == 21: return 1038'i64
  if index == 22: return 772'i64
  if index == 23: return 1030'i64
  if index == 24: return 1028'i64
  if index == 25: return 1027'i64
  0'i64
proc separator(text:ptr UncheckedArray[int64],p,finish:int):bool=p+2<finish and text[p]==32 and text[p+1]==124 and text[p+2]==32
proc decodeToken(text:ptr UncheckedArray[int64],start,finish:int):uint8=
  for letter in 0..<26:
    let word=morseWord(letter);let length=int((word div 256) mod 8)
    if finish-start!=length:continue
    let mask=word mod 32;var matches=true
    for bit in 0..<length:
      let expected=if ((mask shr (length-bit-1)) and 1)!=0:46'i64 else:45'i64
      if text[start+bit]!=expected:matches=false
    if matches:return uint8(65+letter)
  63'u8
proc appendWord(text:ptr UncheckedArray[int64],start,finishValue:int,scratch:var array[MAX_OUTPUT_BYTES,uint8],written:var int)=
  if start==finishValue:scratch[written]=63'u8;inc written;return
  var finish=finishValue
  while finish>start and text[finish-1]==32:dec finish
  if start==finish:return
  var token=start
  for p in start..finish:
    if p==finish or text[p]==32:scratch[written]=decodeToken(text,token,p);inc written;token=p+1
proc decode(text:ptr UncheckedArray[int64],length:int,scratch:var array[MAX_OUTPUT_BYTES,uint8]):int=
  if length==0:scratch[0]=63'u8;return 1
  var finish=length
  while finish>=3 and separator(text,finish-3,finish):finish-=3
  if finish==0:return 0
  var written=0;var start=0;var p=0
  while p+2<finish:
    if separator(text,p,finish):appendWord(text,start,p,scratch,written);scratch[written]=32'u8;inc written;p+=3;start=p
    else:inc p
  appendWord(text,start,finish,scratch,written)
  written
proc morse_code_converter_decode*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"morse_code_converter_decode".}=
  if (input.isNil and length>0) or length>MAX_INPUT_LENGTH:return -1
  for i in 0..<int(length):if input[i]<0 or input[i]>127:return -1
  var scratch:array[MAX_OUTPUT_BYTES,uint8]
  let written=decode(input,int(length),scratch)
  if output.isNil or capacity<written:return -2
  for i in 0..<written:output[i]=scratch[i]
  int64(written)
