module validate_email;
fn bool ascii_space(long c){return c==9||c==10||c==11||c==12||c==13||c==32;}
fn long validate_email(long* v,usz n) @export("validate_email") {
    if(v==null||n<2||n>1025||v[0]<1||v[0]>1024||(usz)v[0]+1!=n)return -1;
    usz end=(usz)v[0];for(usz i=0;i<end;i++)if(v[i+1]<0||v[i+1]>127)return -1;
    usz at=end;for(usz i=0;i<end;i++){long c=v[i+1];if(ascii_space(c))return 0;if(c=='@'){if(at!=end)return 0;at=i;}}
    if(at==0||at>=end-1)return 0;
    bool dot=false;usz i=at+2;while(i+1<end){if(v[i+1]=='.')dot=true;i++;}return dot?1:0;
}
