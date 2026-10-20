"""Independent exhaustive support-set oracle for the bounded 3D miniball."""
from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
import math

MAX_POINTS = 8
MAX_INPUT_LENGTH = 1 + 3 * MAX_POINTS
MAX_OUTPUT_ELEMENTS = 4
INVALID_RESULT = -1
OUTPUT_ERROR = -2
EPS = 1e-10

def _sub(a, b): return tuple(x-y for x,y in zip(a,b))
def _add(a, b): return tuple(x+y for x,y in zip(a,b))
def _scale(a, s): return tuple(x*s for x in a)
def _dot(a, b): return sum(x*y for x,y in zip(a,b))
def _cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def _sphere(points):
    if len(points) == 1: return points[0], 0.0
    if len(points) == 2:
        c = _scale(_add(points[0], points[1]), 0.5)
        return c, math.sqrt(_dot(_sub(points[0], c), _sub(points[0], c)))
    p0 = points[0]
    if len(points) == 3:
        u, v = _sub(points[1], p0), _sub(points[2], p0)
        n = _cross(u, v); den = 2.0 * _dot(n, n)
        if abs(den) <= 1e-20: return None
        off = _scale(_add(_scale(_cross(v, n), _dot(u,u)), _scale(_cross(n,u), _dot(v,v))), 1.0/den)
        c = _add(p0, off)
    else:
        rows=[]; rhs=[]
        q0=_dot(p0,p0)
        for p in points[1:]:
            rows.append([2.0*(p[i]-p0[i]) for i in range(3)])
            rhs.append(_dot(p,p)-q0)
        a=[rows[i]+[rhs[i]] for i in range(3)]
        for col in range(3):
            pivot=max(range(col,3),key=lambda r:abs(a[r][col]))
            if abs(a[pivot][col]) <= 1e-18: return None
            a[col],a[pivot]=a[pivot],a[col]
            z=a[col][col];a[col]=[v/z for v in a[col]]
            for r in range(3):
                if r!=col:
                    z=a[r][col];a[r]=[a[r][j]-z*a[col][j] for j in range(4)]
        c=tuple(a[i][3] for i in range(3))
    d=_sub(points[0],c)
    return c,math.sqrt(_dot(d,d))

def _minimum_ball(points):
    best=None
    for size in range(1, min(4,len(points))+1):
        for support in combinations(points,size):
            sphere=_sphere(support)
            if sphere is None: continue
            c,r=sphere
            if all(_dot(_sub(p,c),_sub(p,c)) <= (r+EPS)**2 for p in points):
                if best is None or r < best[1]-EPS: best=(c,r)
    return best

def expected_output(values: Sequence[float] | None, output_capacity: int | None = 4,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool: return -1,[]
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0): return -1,[]
    if input_length is not None and (type(input_length) is not int or input_length < 0): return -1,[]
    if input_is_null or values is None or not isinstance(values,(list,tuple)): return INVALID_RESULT,[]
    if input_length is not None and input_length!=len(values): return INVALID_RESULT,[]
    if not 4<=len(values)<=MAX_INPUT_LENGTH: return INVALID_RESULT,[]
    if any(type(v) not in (int,float) or not math.isfinite(float(v)) for v in values): return INVALID_RESULT,[]
    n=int(values[0])
    if float(values[0])!=n or not 1<=n<=MAX_POINTS or len(values)!=1+3*n: return INVALID_RESULT,[]
    flat=[float(v) for v in values[1:]]
    if any(not -10.0<=v<=10.0 for v in flat): return INVALID_RESULT,[]
    pts=[tuple(flat[i:i+3]) for i in range(0,len(flat),3)]
    ball=_minimum_ball(pts)
    if ball is None: return INVALID_RESULT,[]
    if output_is_null or (output_capacity is not None and output_capacity<MAX_OUTPUT_ELEMENTS): return OUTPUT_ERROR,[]
    return MAX_OUTPUT_ELEMENTS,[*ball[0],ball[1]]
