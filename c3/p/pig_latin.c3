module pig_latin;
fn long pig_latin(long* v,usz n,char* out,usz cap) @export("pig_latin") {
    if(v==null||n<1||n>65||v[0]<0||v[0]>64||n!=(usz)v[0]+1)return -1;
    usz count=(usz)v[0];if(count==0)return 0;if(count+3>cap||out==null)return -2;usz pivot=count;
    for(usz i=0;i<count;i++){long x=v[i+1];if(x>=65&&x<=90)x+=32;if(x<97||x>122)return -1;out[i]=(char)x;if(pivot==count&&(x==97||x==101||x==105||x==111||x==117))pivot=i;}
    if(pivot==count)return -1;
    if(pivot==0){out[count]='w';out[count+1]='a';out[count+2]='y';return (long)(count+3);}
    for(usz i=0;i<pivot;i++)out[count+i]=out[i];for(usz i=0;i<count-pivot;i++)out[i]=out[pivot+i];out[count]='a';out[count+1]='y';return (long)(count+2);
}
