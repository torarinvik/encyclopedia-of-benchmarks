## Convert fully parenthesized bounded ASCII infix expressions to prefix.
const MaxExpression = 256
proc isOperand(c:int64):bool = (c>=48 and c<=57) or (c>=65 and c<=90) or (c>=97 and c<=122)
proc isOperator(c:int64):bool = c in [43'i64,45,42,47,94]
proc precedence(c:int64):int64 = if c in [43'i64,45]:1 elif c in [42'i64,47]:2 else:3
proc valid(input:ptr UncheckedArray[int64], n:int):bool =
  var stage:array[MaxExpression,uint8];var depth=0;var done=false
  for i in 0..<n:
    let ch=input[i]
    if depth==0:
      if done:return false
      if isOperand(ch):done=true
      elif ch==40:stage[depth]=0;inc depth
      else:return false
    elif stage[depth-1]==0 or stage[depth-1]==2:
      if isOperand(ch):stage[depth-1]=if stage[depth-1]==0:1 else:3
      elif ch==40 and depth<MaxExpression:stage[depth]=0;inc depth
      else:return false
    elif stage[depth-1]==1:
      if not isOperator(ch):return false
      stage[depth-1]=2
    else:
      if ch!=41:return false
      dec depth
      if depth==0:done=true
      elif stage[depth-1]==0:stage[depth-1]=1
      elif stage[depth-1]==2:stage[depth-1]=3
      else:return false
  depth==0 and done
proc infix_to_prefix*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"infix_to_prefix".} =
  if length>csize_t(MaxExpression) or (length>0 and input.isNil):return -1
  if length==0:return 0
  if not valid(input,int(length)):return -1
  var stack:array[MaxExpression,uint8];var post:array[MaxExpression,uint8];var top=0;var count=0
  var i=int(length)
  while i>0:
    dec i;let ch=input[i]
    if isOperand(ch):post[count]=uint8(ch);inc count
    elif ch==41:stack[top]=41;inc top
    elif ch==40:
      while top>0 and stack[top-1]!=41:dec top;post[count]=stack[top];inc count
      if top>0:dec top
    else:
      while top>0 and stack[top-1]!=41 and precedence(ch)<precedence(int64(stack[top-1])):dec top;post[count]=stack[top];inc count
      stack[top]=uint8(ch);inc top
  while top>0:dec top;post[count]=stack[top];inc count
  if capacity<csize_t(count) or (count>0 and output.isNil):return -2
  for j in 0..<count:output[j]=post[count-1-j]
  int64(count)
