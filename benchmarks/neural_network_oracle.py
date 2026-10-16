"""Oracle for a bounded one-hidden-layer sigmoid MLP inference pass."""
import math, struct
MAX_INPUT_LENGTH=24
MAX_OUTPUT_BYTES=24

def expected_output(v):
    if not isinstance(v,(list,tuple)) or any(type(x) is not int or not -(2**63)<=x<2**63 for x in v):return -1,b""
    if len(v)<7:return -1,b""
    ni,nh,no=v[:3]
    if not 1<=ni<=3 or not 1<=nh<=3 or not 1<=no<=3:return -1,b""
    if len(v)!=3+ni+ni*nh+nh*no:return -1,b""
    xs=v[3:3+ni];a=v[3+ni:3+ni+ni*nh];b=v[3+ni+ni*nh:]
    if any(not -1000<=x<=1000 for x in xs+a+b):return -1,b""
    def sig(z):return 1.0/(1.0+math.exp(-z))
    h=[]
    for j in range(nh):h.append(sig(sum((xs[i]/1000.0)*(a[i*nh+j]/1000.0) for i in range(ni))))
    y=[sig(sum(h[i]*(b[i*no+j]/1000.0) for i in range(nh))) for j in range(no)]
    return 8*no,struct.pack('<'+'d'*no,*y)
