"""Oracle for the pinned Rust Gaussian Naive Bayes classifier."""
import math, struct
MAX_INPUT_LENGTH=37
MAX_OUTPUT_BYTES=8

def expected_output(v):
    if not isinstance(v,(list,tuple)) or any(type(x) is not int or not -(2**63)<=x<2**63 for x in v):return -1,b""
    if len(v)<6:return -1,b""
    n,f=v[:2]
    if not 2<=n<=8 or not 1<=f<=3 or len(v)!=2+n*(f+1)+f:return -1,b""
    rows=[];p=2;classes=[]
    for _ in range(n):
        label=v[p];xs=v[p+1:p+1+f];p+=f+1
        if label not in (0,1,2) or any(not -10000<=x<=10000 for x in xs):return -1,b""
        if label not in classes:classes.append(label)
        rows.append((label,[x/1000.0 for x in xs]))
    query=[x/1000.0 for x in v[p:]]
    if len(classes)<2 or any(not -10000<=x<=10000 for x in v[p:]):return -1,b""
    best=None;best_score=-math.inf
    for c in classes:
        samples=[x for label,x in rows if label==c]
        score=math.log(len(samples)/n)
        for j,q in enumerate(query):
            mean=sum(x[j] for x in samples)/len(samples)
            var=max(sum((x[j]-mean)**2 for x in samples)/len(samples),1e-9)
            score+=-0.5*math.log(2*math.pi*var)-(q-mean)**2/(2*var)
        if score>best_score:best,best_score=c,score
    return 8,struct.pack('<q',best)
