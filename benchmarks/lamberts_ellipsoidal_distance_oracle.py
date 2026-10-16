from collections.abc import Sequence
from math import asin,atan,cos,radians,sin,sqrt,tan
INVALID_RESULT=-1.0e300
MAX_INPUT_LENGTH=4
AXIS_A=6378137.0
AXIS_B=6356752.314245
EARTH_RADIUS=6371000
EQUATORIAL_RADIUS=6378137
def expected_result(values:Sequence[int])->float:
    if not isinstance(values,(list,tuple)) or len(values)!=4:return INVALID_RESULT
    if any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in values):return INVALID_RESULT
    lat1,lon1,lat2,lon2=values
    if not (-90_000_000<=lat1<=90_000_000 and -90_000_000<=lat2<=90_000_000 and -180_000_000<=lon1<=180_000_000 and -180_000_000<=lon2<=180_000_000):return INVALID_RESULT
    if lat1==lat2 and lon1==lon2:return INVALID_RESULT
    latitude1=lat1/1_000_000;longitude1=lon1/1_000_000;latitude2=lat2/1_000_000;longitude2=lon2/1_000_000
    p1=radians(latitude1);p2=radians(latitude2);l1=radians(longitude1);l2=radians(longitude2)
    h=sqrt(sin((p2-p1)/2)**2+cos(p1)*cos(p2)*sin((l2-l1)/2)**2)
    if h==0.0:return INVALID_RESULT
    sigma=(2*EARTH_RADIUS*asin(h))/EARTH_RADIUS
    flattening=(AXIS_A-AXIS_B)/AXIS_A
    b1=atan((1-flattening)*tan(radians(latitude1)))
    b2=atan((1-flattening)*tan(radians(latitude2)))
    p=(b1+b2)/2;q=(b2-b1)/2
    x=(sigma-sin(sigma))*((sin(p)**2*cos(q)**2)/(cos(sigma/2)**2))
    y=(sigma+sin(sigma))*((cos(p)**2*sin(q)**2)/(sin(sigma/2)**2))
    return EQUATORIAL_RADIUS*(sigma-(flattening/2)*(x+y))
