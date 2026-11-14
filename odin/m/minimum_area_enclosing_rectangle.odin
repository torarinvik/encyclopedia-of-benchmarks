package minimum_area_enclosing_rectangle
import "core:c"

projection :: proc(input: [^]i64, index: int, dx,dy: i64, axis: int) -> i64 {
    x,y:=input[1+2*index],input[2+2*index]
    if axis==2 do return dx*y-dy*x
    return dx*x+dy*y
}

@(export)
minimum_area_enclosing_rectangle :: proc "c" (input: [^]i64, length: c.size_t,
                                                output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<7 || length>34 do return -1
    if input[0]<3 || input[0]>16 do return -1
    n:=int(input[0])
    if length!=c.size_t(1+2*n) do return -1
    for i:=1; i<int(length); i+=1 { if input[i]< -100 || input[i]>100 do return -1 }
    for i:=0; i<n; i+=1 {
        next:=(i+1)%n; ax,ay:=input[1+2*i],input[2+2*i]
        dx,dy:=input[1+2*next]-ax,input[2+2*next]-ay
        for j:=0; j<n; j+=1 {
            if j!=i && j!=next && dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0 do return -1
        }
    }
    first_dx,first_dy:=input[3]-input[1],input[4]-input[2]
    supports: [3]int = {}
    for i:=1; i<n; i+=1 { for axis:=0; axis<3; axis+=1 {
        current:=projection(input,supports[axis],first_dx,first_dy,axis)
        candidate:=projection(input,i,first_dx,first_dy,axis)
        if (axis==1 && candidate<current) || (axis!=1 && candidate>current) { supports[axis]=i }
    } }
    best_num,best_den:=i64(0),i64(1)
    for i:=0; i<n; i+=1 {
        next:=(i+1)%n; ax,ay:=input[1+2*i],input[2+2*i]
        dx,dy:=input[1+2*next]-ax,input[2+2*next]-ay
        for axis:=0; axis<3; axis+=1 { for steps:=0; steps<n; steps+=1 {
            following:=(supports[axis]+1)%n
            current:=projection(input,supports[axis],dx,dy,axis)
            candidate:=projection(input,following,dx,dy,axis)
            if (axis==1 && candidate<=current) || (axis!=1 && candidate>=current) { supports[axis]=following } else { break }
        } }
        span:=projection(input,supports[0],dx,dy,0)-projection(input,supports[1],dx,dy,1)
        thickness:=projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax)
        numerator,denominator:=span*thickness,dx*dx+dy*dy
        if i==0 || numerator*best_den<best_num*denominator { best_num=numerator; best_den=denominator }
    }
    a,b:=best_num,best_den
    for b!=0 { remainder:=a%b; a=b; b=remainder }
    words:=[2]i64{best_num/a,best_den/a}
    if output==nil || capacity<16 do return -2
    for i:=0; i<2; i+=1 {
        bits:=u64(words[i])
        for j:=0; j<8; j+=1 { output[8*i+j]=u8(bits >> u64(8*j)) }
    }
    return 16
}
