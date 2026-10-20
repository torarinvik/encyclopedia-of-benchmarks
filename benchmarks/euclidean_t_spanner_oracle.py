"""Independent bounded ParGeo-style WSPD representative-edge model."""
from __future__ import annotations
from collections.abc import Sequence
import math

MAX_POINTS=8
MAX_EDGES=28
MAX_INPUT_LENGTH=2+2*MAX_POINTS
MAX_OUTPUT_ELEMENTS=1+2*MAX_EDGES

def _tree(points, ids):
    xs=[points[i][0] for i in ids];ys=[points[i][1] for i in ids]
    xmin,xmax=min(xs),max(xs);ymin,ymax=min(ys),max(ys)
    node={"ids":ids,"rep":min(ids),"cx":(xmin+xmax)/2,"cy":(ymin+ymax)/2,
          "rx":(xmax-xmin)/2,"ry":(ymax-ymin)/2,"left":None,"right":None}
    if len(ids)>1:
        axis=0 if xmax-xmin>=ymax-ymin else 1
        ordered=sorted(ids,key=lambda i:(points[i][axis],points[i][1-axis],i));mid=len(ordered)//2
        node["left"]=_tree(points,ordered[:mid]);node["right"]=_tree(points,ordered[mid:])
    node["span"]=max(xmax-xmin,ymax-ymin)
    node["radius"]=math.hypot(node["rx"],node["ry"])
    return node

def _edges(root,t):
    s=4.0*(t+1.0)/(t-1.0);out=[]
    def cross(a,b):
        dx=a["cx"]-b["cx"];dy=a["cy"]-b["cy"]
        dist=math.hypot(dx,dy);ra=a["radius"];rb=b["radius"]
        if dist-ra-rb>=s*max(ra,rb):
            i,j=sorted((a["rep"],b["rep"]));out.append((i,j));return
        if a["left"] is None:
            cross(b["left"],a);cross(b["right"],a)
        elif b["left"] is None:
            cross(a["left"],b);cross(a["right"],b)
        elif a["span"]>b["span"]:
            cross(a["left"],b);cross(a["right"],b)
        else:
            cross(a,b["left"]);cross(a,b["right"])
    def visit(node):
        if node["left"] is not None:
            visit(node["left"]);visit(node["right"]);cross(node["left"],node["right"])
    visit(root)
    return out

def expected_output(values:Sequence[float]|None,output_capacity:int|None=None,
                    output_is_null:bool=False,input_is_null:bool=False,
                    input_length:int|None=None)->tuple[int,list[float]]:
    if type(output_is_null)is not bool or type(input_is_null)is not bool or input_is_null or not isinstance(values,(list,tuple)):return -1,[]
    if input_length is not None and (type(input_length)is not int or input_length!=len(values)):return -1,[]
    if output_capacity is not None and (type(output_capacity)is not int or output_capacity<0):return -1,[]
    if not 6<=len(values)<=2+2*MAX_POINTS or any(type(v) not in (int,float) or not math.isfinite(float(v)) for v in values):return -1,[]
    raw_n,t=float(values[0]),float(values[1])
    if raw_n!=int(raw_n) or not 2<=int(raw_n)<=MAX_POINTS or not 1.5<=t<=4 or len(values)!=2+2*int(raw_n):return -1,[]
    n=int(raw_n);points=[]
    for i in range(n):
        x,y=float(values[2+2*i]),float(values[3+2*i])
        if not -1000<=x<=1000 or not -1000<=y<=1000 or x!=math.trunc(x) or y!=math.trunc(y):return -1,[]
        points.append((int(x),int(y)))
    if len(set(points))!=n:return -1,[]
    edges=_edges(_tree(points,list(range(n))),t)
    if len(edges)>MAX_EDGES:return -1,[]
    out=[float(len(edges))]
    for u,v in edges:out.extend((float(u),float(v)))
    if output_is_null or (output_capacity is not None and output_capacity<len(out)):return -2,[]
    return len(out),out
