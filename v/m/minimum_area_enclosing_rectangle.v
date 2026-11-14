fn maer_projection(input &i64, index int, dx i64, dy i64, axis int) i64 {
    unsafe {
        x,y:=input[1+2*index],input[2+2*index]
        return if axis==2 { dx*y-dy*x } else { dx*x+dy*y }
    }
}

@[export: 'minimum_area_enclosing_rectangle']
pub fn minimum_area_enclosing_rectangle(input &i64, length usize, output &u8, capacity usize) i64 {
    if length<7 || length>34 { return -1 }
    unsafe {
        if input==nil || input[0]<3 || input[0]>16 { return -1 }
        n:=int(input[0])
        if length!=usize(1+2*n) { return -1 }
        for i in 1 .. int(length) { if input[i]< -100 || input[i]>100 { return -1 } }
        for i in 0 .. n {
            next:=(i+1)%n
            ax,ay:=input[1+2*i],input[2+2*i]
            dx,dy:=input[1+2*next]-ax,input[2+2*next]-ay
            for j in 0 .. n {
                if j!=i && j!=next && dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0 { return -1 }
            }
        }
        first_dx,first_dy:=input[3]-input[1],input[4]-input[2]
        mut supports:=[3]int{}
        for i in 1 .. n { for axis in 0 .. 3 {
            current:=maer_projection(input,supports[axis],first_dx,first_dy,axis)
            candidate:=maer_projection(input,i,first_dx,first_dy,axis)
            if (axis==1 && candidate<current) || (axis!=1 && candidate>current) { supports[axis]=i }
        } }
        mut best_num:=i64(0)
        mut best_den:=i64(1)
        for i in 0 .. n {
            next:=(i+1)%n
            ax,ay:=input[1+2*i],input[2+2*i]
            dx,dy:=input[1+2*next]-ax,input[2+2*next]-ay
            for axis in 0 .. 3 { for _ in 0 .. n {
                following:=(supports[axis]+1)%n
                current:=maer_projection(input,supports[axis],dx,dy,axis)
                candidate:=maer_projection(input,following,dx,dy,axis)
                if (axis==1 && candidate<=current) || (axis!=1 && candidate>=current) { supports[axis]=following } else { break }
            } }
            span:=maer_projection(input,supports[0],dx,dy,0)-maer_projection(input,supports[1],dx,dy,1)
            thickness:=maer_projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax)
            numerator,denominator:=span*thickness,dx*dx+dy*dy
            if i==0 || numerator*best_den<best_num*denominator { best_num=numerator; best_den=denominator }
        }
        mut a:=best_num
        mut b:=best_den
        for b!=0 { remainder:=a%b; a=b; b=remainder }
        words:=[best_num/a,best_den/a]
        if output==nil || capacity<16 { return -2 }
        for i in 0 .. 2 {
            bits:=u64(words[i])
            for j in 0 .. 8 { output[8*i+j]=u8(bits >> (8*j)) }
        }
        return 16
    }
}
