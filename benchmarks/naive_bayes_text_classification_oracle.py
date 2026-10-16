"""Oracle for the one-token-per-document bounded multinomial NB classifier."""
import math
import struct

MAX_INPUT_LENGTH = 71
MAX_OUTPUT_BYTES = 16

def _token(chars):
    out=[]
    for x in chars:
        if 65<=x<=90: x+=32
        if 97<=x<=122 or 48<=x<=57 or x==39: out.append(chr(x))
        else: raise ValueError
    key=0
    for ch in out:key=key*128+ord(ch)
    return key

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or len(values)<7
            or any(type(x) is not int or not -(2**63)<=x<2**63 for x in values)):
        return -1,b""
    n,alpha=values[:2]
    if not 2<=n<=6 or not 1<=alpha<=10000:return -1,b""
    pos=2;docs=[];labels=[]
    try:
        for _ in range(n):
            if pos+2>len(values):return -1,b""
            label,length=values[pos],values[pos+1];pos+=2
            if label not in (0,1) or not 0<=length<=8 or pos+length>len(values):return -1,b""
            docs.append(_token(values[pos:pos+length]));labels.append(label);pos+=length
        if pos>=len(values):return -1,b""
        qlen=values[pos];pos+=1
        if not 0<=qlen<=8 or pos+qlen!=len(values):return -1,b""
        query=_token(values[pos:])
    except ValueError:
        return -1,b""
    if set(labels)!={0,1}:return -1,b""
    vocab=set(t for t in docs if t)
    if not vocab and query:return -1,b""
    scores=[]
    a=alpha/1000.0
    for cls in (0,1):
        dc=sum(label==cls for label in labels)
        prior=math.log(dc/n)
        total=sum(bool(t) for t,label in zip(docs,labels) if label==cls)
        score=prior
        if query:
            count=sum(t==query and label==cls for t,label in zip(docs,labels))
            score+=math.log((count+a)/(total+a*len(vocab)))
        scores.append(score)
    high=max(scores); ex=[math.exp(x-high) for x in scores]; den=sum(ex)
    payload=struct.pack('<dd',ex[0]/den,ex[1]/den)
    return 16,payload
