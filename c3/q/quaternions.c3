module quaternions;

extern fn float sinf(float value);
extern fn float cosf(float value);
extern fn float asinf(float value);
extern fn float atan2f(float y,float x);

fn long quaternions(double* input,usz length,double* output,usz output_capacity) @export("quaternions"){
 if(input==null||length<1||length>10)return -1;for(usz i=0;i<length;i++)if(input[i]!=input[i])return -1;
 double op=input[0];if(op!=0.0&&op!=1.0&&op!=2.0)return -1;long mode=(long)op;usz expected=mode==0?4:mode==1?5:9;usz count=mode==1?3:4;if(length!=expected)return -1;
 float v[8];
 if(mode==0){for(usz i=1;i<4;i++){if(input[i]<-3.0||input[i]>3.0)return -1;v[i-1]=(float)input[i];}}
 else if(mode==1){for(usz i=1;i<5;i++){v[i-1]=(float)input[i];if(v[i-1]<-1.0||v[i-1]>1.0)return -1;}float w=v[0],a=v[1],b=v[2],c=v[3];float norm=w*w;norm=norm+a*a;norm=norm+b*b;norm=norm+c*c;if(norm-1.0>1e-6||1.0-norm>1e-6)return -1;float pa=w*b+a*c;pa=2.0*pa;if(pa < -1.0||pa>1.0)return -1;}
 else{for(usz i=1;i<9;i++){if(input[i]<-1.0||input[i]>1.0)return -1;v[i-1]=(float)input[i];}}
 if(output==null||output_capacity<count)return -2;float r[4];
 if(mode==0){float y=v[0],p=v[1],roll=v[2];float cy=cosf(y*0.5),sy=sinf(y*0.5),cp=cosf(p*0.5),sp=sinf(p*0.5),cr=cosf(roll*0.5),sr=sinf(roll*0.5);r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy;}
 else if(mode==1){float w=v[0],a=v[1],b=v[2],c=v[3];float ry=2.0*(w*a+b*c),rx=1.0-2.0*(a*a+b*b),pitch=asinf(2.0*(w*b+a*c)),yy=2.0*(w*c+a*b),yx=1.0-2.0*(b*b+c*c);r[0]=atan2f(ry,rx);r[1]=pitch;r[2]=atan2f(yy,yx);}
 else{float aw=v[0],a1=v[1],a2=v[2],a3=v[3],bw=v[4],b1=v[5],b2=v[6],b3=v[7];r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw;}
 for(usz i=0;i<count;i++)output[i]=(double)r[i];return (long)count;
}
