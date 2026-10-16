from collections.abc import Sequence
MAX_INPUT_LENGTH=8
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=8:return -1
    if any(type(x)is not int or not -5<=x<=5 for x in values):return -1
    xmin,ymin,xmax,ymax,x0,y0,x1,y1=values
    if xmin>=xmax or ymin>=ymax:return -1
    dx=x1-x0;dy=y1-y0
    p=(-dx,dx,-dy,dy);q=(x0-xmin,xmax-x0,y0-ymin,ymax-y0)
    t0=0.0;t1=1.0
    for pi,qi in zip(p,q):
        t=qi/pi if pi else (float('inf') if qi>0 else (float('-inf') if qi<0 else float('nan')))
        if pi==0 and qi<0:return -1
        elif pi<0:
            if t>t1:return -1
            if t>t0:t0=t
        elif pi>0:
            if t<t0:return -1
            if t<t1:t1=t
    pts=(x0+t0*dx,y0+t0*dy,x0+t1*dx,y0+t1*dy)
    scaled=[]
    for x in pts:
        z=x*1000
        r=int(z+0.5) if z>=0 else -int(-z+0.5)
        scaled.append(r)
    packed=0
    for x in scaled:packed=packed*10001+(x+5000)
    return packed
