module felsenstein_substitution_likelihood;

fn void put_i64(uint8* out,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[b]=(uint8)(bits>>(8*b));}

fn long felsenstein_substitution_likelihood(long* input,usz length,uint8* output,usz capacity) @export("felsenstein_substitution_likelihood") {
    if(input==null||length<3||length>38)return -1;
    long n=input[0];if(n<1||n>8)return -1;
    long[16] stack;long sp=0,leaves=0,joins=0,edges=0;usz at=1;
    while(at<length){long tag=input[at];at++;
        if(tag==0){if(at>=length||input[at]<0||input[at]>1||sp>=8)return -1;long state=input[at];at++;stack[sp*2]=state==0?1:0;stack[sp*2+1]=state==1?1:0;sp++;leaves++;}
        else if(tag==1){if(at+2>length||sp<2||input[at]<0||input[at]>1||input[at+1]<0||input[at+1]>1)return -1;long lm=input[at],rm=input[at+1];at+=2;long li=(sp-2)*2,ri=(sp-1)*2;
            for(long parent=0;parent<2;parent++){long l=lm==0?4*stack[li+parent]:3*stack[li+parent]+stack[li+1-parent];long r=rm==0?4*stack[ri+parent]:3*stack[ri+parent]+stack[ri+1-parent];stack[li+parent]=l*r;}
            sp--;joins++;edges+=2;
        }else return -1;
    }
    if(leaves!=n||joins!=n-1||sp!=1||edges!=2*n-2)return -1;
    long shift=29-2*edges;if(shift<0)return -1;long scaled=(stack[0]+stack[1])<<shift;
    if(output==null||capacity<8)return -2;put_i64(output,scaled);return 8;
}
