module cbench_rsynth_f0_flutter;

extern fn double sin(double value);
fn long cbench_rsynth_f0_flutter(long* input, usz n) @export("cbench_rsynth_f0_flutter") {
    if(input==null||n==0||n>4)return -1;
    if(n!=3||input[0]<0||input[0]>20000||input[1]<0||input[1]>100||input[2]<0||input[2]>1000000)return -1;
    long f0=input[0],flutter=input[1],t=input[2],original=f0/10;double pi=3.1415927;
    double fla=(double)flutter/50.0,flb=(double)original/100.0;
    double flc=sin(2.0*pi*12.7*(double)t),fld=sin(2.0*pi*7.1*(double)t),fle=sin(2.0*pi*4.7*(double)t);
    double delta=fla*flb*(flc+fld+fle)*10.0;
    return f0+(long)delta;
}
