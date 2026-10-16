const MAX_INPUT_LENGTH=512
const MAX_OUTPUT_BYTES=2560
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
proc letterIndex(value:int64):int =
  if value>=65 and value<=90:return int(value-65)
  if value>=97 and value<=122:return int(value-97)
  -1
proc appendWord(text:ptr UncheckedArray[int64],start,finish:int,scratch:var array[MAX_OUTPUT_BYTES,uint8],written:var int)=
  for p in start..<finish:
    let letter=letterIndex(text[p])
    if letter>=0:
      let word=morseWord(letter);let length=int((word div 256) mod 8);let mask=word mod 32
      for bit in 0..<length:
        let shift=length-bit-1
        scratch[written]=if ((mask shr shift) and 1)!=0:46'u8 else:45'u8
        inc written
    scratch[written]=32'u8;inc written
proc encode(text:ptr UncheckedArray[int64],length:int,scratch:var array[MAX_OUTPUT_BYTES,uint8]):int=
  var finish=length
  while finish>0 and text[finish-1]==32:dec finish
  if finish==0:return 0
  var written=0;var start=0
  for p in 0..finish:
    if p==finish or text[p]==32:
      appendWord(text,start,p,scratch,written)
      if p<finish:scratch[written]=124'u8;inc written;scratch[written]=32'u8;inc written
      start=p+1
  while written>0 and scratch[written-1]==32'u8:dec written
  written
proc morse_code_converter_encode*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"morse_code_converter_encode".}=
  if (input.isNil and length>0) or length>MAX_INPUT_LENGTH:return -1
  for i in 0..<int(length):if input[i]<0 or input[i]>127:return -1
  var scratch:array[MAX_OUTPUT_BYTES,uint8]
  let written=encode(input,int(length),scratch)
  if output.isNil or capacity<written:return -2
  for i in 0..<written:output[i]=scratch[i]
  int64(written)
