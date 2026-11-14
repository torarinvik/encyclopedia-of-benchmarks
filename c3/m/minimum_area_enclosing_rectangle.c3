module minimum_area_enclosing_rectangle;

fn long projection(long* input, usz index, long dx, long dy, usz axis) {
    long x=input[1+2*index], y=input[2+2*index];
    return axis==2 ? dx*y-dy*x : dx*x+dy*y;
}

fn long minimum_area_enclosing_rectangle(long* input, usz length, char* output, usz capacity)
    @export("minimum_area_enclosing_rectangle") {
    if (input==null || length<7 || length>34 || input[0]<3 || input[0]>16) return -1;
    usz n=input[0].usz();
    if (length!=1+2*n) return -1;
    for (usz i=1; i<length; i++) if (input[i]< -100 || input[i]>100) return -1;
    for (usz i=0; i<n; i++) {
        usz next=(i+1)%n;
        long ax=input[1+2*i], ay=input[2+2*i], dx=input[1+2*next]-ax, dy=input[2+2*next]-ay;
        for (usz j=0; j<n; j++) if (j!=i && j!=next)
            if (dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0) return -1;
    }
    long first_dx=input[3]-input[1], first_dy=input[4]-input[2];
    usz[3] supports=zeroed;
    for (usz i=1; i<n; i++) for (usz axis=0; axis<3; axis++) {
        long current=projection(input,supports[axis],first_dx,first_dy,axis);
        long candidate=projection(input,i,first_dx,first_dy,axis);
        if ((axis==1 && candidate<current) || (axis!=1 && candidate>current)) supports[axis]=i;
    }
    long best_num=0, best_den=1;
    for (usz i=0; i<n; i++) {
        usz next=(i+1)%n;
        long ax=input[1+2*i], ay=input[2+2*i], dx=input[1+2*next]-ax, dy=input[2+2*next]-ay;
        for (usz axis=0; axis<3; axis++) for (usz steps=0; steps<n; steps++) {
            usz following=(supports[axis]+1)%n;
            long current=projection(input,supports[axis],dx,dy,axis);
            long candidate=projection(input,following,dx,dy,axis);
            if ((axis==1 && candidate<=current) || (axis!=1 && candidate>=current)) supports[axis]=following;
            else break;
        }
        long span=projection(input,supports[0],dx,dy,0)-projection(input,supports[1],dx,dy,1);
        long thickness=projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax);
        long numerator=span*thickness, denominator=dx*dx+dy*dy;
        if (i==0 || numerator*best_den<best_num*denominator) { best_num=numerator; best_den=denominator; }
    }
    long a=best_num, b=best_den;
    while (b!=0) { long remainder=a%b; a=b; b=remainder; }
    long[2] words={best_num/a,best_den/a};
    if (output==null || capacity<16) return -2;
    for (usz i=0; i<2; i++) {
        ulong bits=(ulong)words[i];
        for (usz j=0; j<8; j++) { output[8*i+j]=(char)(bits & 255); bits>>=8; }
    }
    return 16;
}
