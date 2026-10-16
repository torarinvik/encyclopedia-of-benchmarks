module postfix_to_infix;
fn bool is_letter(long x){return (x>=65&&x<=90)||(x>=97&&x<=122);}
fn bool is_operator(long x){return x==43||x==45||x==42||x==47||x==94;}
fn long postfix_to_infix(long* v,usz n,char* out,usz cap) @export("postfix_to_infix"){
    if(v==null||n<1||n>65||v[0]<0||v[0]>64||n!=(usz)v[0]+1)return -1;
    if(out==null||cap<8192)return -2;
    usz count=(usz)v[0];if(count==0)return 0;
    if(count==1){if(!is_letter(v[1]))return -1;out[0]=(char)v[1];return 1;}
    usz[64] starts;usz[64] lengths;usz stack=0,scratch=256;
    for(usz i=0;i<count;i++){
        long x=v[i+1];
        if(is_operator(x)){
            if(stack<2)return -1;usz l=stack-2,r=stack-1;
            usz ls=starts[l],ll=lengths[l],rs=starts[r],rl=lengths[r];
            usz start=scratch;out[scratch++]='(';for(usz j=0;j<ll;j++)out[scratch++]=out[ls+j];out[scratch++]=(char)x;for(usz j=0;j<rl;j++)out[scratch++]=out[rs+j];out[scratch++]=')';
            starts[l]=start;lengths[l]=scratch-start;stack--;
        }else{if(!is_letter(x))return -1;starts[stack]=scratch;lengths[stack]=1;out[scratch++]=(char)x;stack++;}
        if(scratch>cap)return -2;
    }
    if(stack!=1)return -1;usz start=starts[0],len=lengths[0];for(usz i=0;i<len;i++)out[i]=out[start+i];return (long)len;
}
