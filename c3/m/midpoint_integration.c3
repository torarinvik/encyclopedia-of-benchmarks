module midpoint_integration;
import std::math;
fn void store(long value,char*output){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[b]=(char)((bits>>(8*b))&255);}
fn long midpoint_integration(long* input,usz length,char*output,usz capacity) @export("midpoint_integration"){
 if(input==null||length!=4)return -1;long f=input[0];long steps=input[1];long aa=input[2];long bb=input[3];if(f<0||f>2||steps<1||steps>256||aa< -1000000||aa>1000000||bb<aa||bb>1000000)return -1;if(output==null||capacity<8)return -2;
 double a=(double)aa/1000000.0;double b=(double)bb/1000000.0;double h=(b-a)/(double)steps;double sum=0.0;for(long i=0;i<steps;i++){double x=a+(double)i*h+h/2.0;double y=f==0?1.0:(f==1?x:x*x);sum+=y;}store((long)math::floor(h*sum*1000000000.0+0.5),output);return 8;
}
