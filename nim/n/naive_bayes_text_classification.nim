import math
proc putDouble(outp:ptr UncheckedArray[uint8],off:int,x:float64)=
 let bits=cast[uint64](x)
 for k in 0..<8:outp[off+k]=uint8((bits shr (8*k)) and 255)
proc token(v:ptr UncheckedArray[int64],pos,len:int,key:var uint64):bool=
 key=0
 for i in 0..<len:
  var x=v[pos+i];if x>=65 and x<=90:x+=32
  if not ((x>=97 and x<=122) or (x>=48 and x<=57) or x==39):return false
  key=key*128+uint64(x)
 true
proc naive_bayes_text_classification*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"naive_bayes_text_classification".}=
 if v==nil or n<7:return -1
 let d=v[0];let alpha=v[1];if d<2 or d>6 or alpha<1 or alpha>10000:return -1
 var words:array[6,uint64];var labels:array[6,int];var seen:array[2,bool];var total:array[2,int];var pos=2
 for i in 0..<int(d):
  if pos+2>int(n):return -1
  let lab=v[pos];let length=v[pos+1];pos+=2
  if lab<0 or lab>1 or length<0 or length>8 or pos+int(length)>int(n):return -1
  if not token(v,pos,int(length),words[i]):return -1
  labels[i]=int(lab);seen[labels[i]]=true;if length>0:total[labels[i]]+=1;pos+=int(length)
 if pos>=int(n):return -1
 let qlen=v[pos];pos+=1
 if qlen<0 or qlen>8 or pos+int(qlen)!=int(n) or not seen[0] or not seen[1]:return -1
 var query:uint64
 if not token(v,pos,int(qlen),query):return -1
 var vocab=0
 for i in 0..<int(d):if words[i]!=0:
  var fresh=true
  for j in 0..<i:if words[j]==words[i]:fresh=false
  if fresh:vocab+=1
 if vocab==0 and qlen>0:return -1
 if outp==nil or cap<16:return -2
 var score:array[2,float64]
 for cls in 0..1:
  var docs=0;var count=0
  for i in 0..<int(d):if labels[i]==cls:
   docs+=1
   if qlen>0 and words[i]==query:count+=1
  score[cls]=ln(float64(docs)/float64(d))
  if qlen>0:
   let sm=float64(alpha)/1000.0
   score[cls]+=ln((float64(count)+sm)/(float64(total[cls])+sm*float64(vocab)))
 let hi=max(score[0],score[1]);let a=exp(score[0]-hi);let b=exp(score[1]-hi)
 putDouble(outp,0,a/(a+b));putDouble(outp,8,b/(a+b));16
