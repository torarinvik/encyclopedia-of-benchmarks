"""Independent queue-based oracle for bounded eight-connected flood fill."""
import struct
MAX_SIDE = 32
MAX_INPUT_LENGTH = 6 + MAX_SIDE * MAX_SIDE

def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    width,height,sx,sy,new,target=values[:6]
    if not (1<=width<=MAX_SIDE and 1<=height<=MAX_SIDE and len(values)==6+width*height
            and 0<=sx<width and 0<=sy<height and -(2**31)<=new<2**31
            and -(2**31)<=target<2**31 and new!=target):
        return -1, b""
    image=values[6:]
    if any(not -(2**31)<=x<2**31 for x in image): return -1,b""
    image=list(image)
    queue=[]
    start=sx*height+sy
    if image[start]==target:
        image[start]=new
        queue.append(start)
    head=0
    while head<len(queue):
        idx=queue[head];head+=1
        x,y=divmod(idx,height)
        for dx in (-1,0,1):
            for dy in (-1,0,1):
                if dx==0 and dy==0: continue
                nx,ny=x+dx,y+dy
                if 0<=nx<width and 0<=ny<height:
                    j=nx*height+ny
                    if image[j]==target:
                        image[j]=new
                        queue.append(j)
    return len(image)*8,b''.join(struct.pack('<q',x) for x in image)
