module is_strong_password;

const long MAX_TEXT_LENGTH=256;

fn long is_strong_password(long *v,usz n) @export("is_strong_password") {
    if(v==null||n<2||n>258)return -1;
    long minimum=v[0],text_length=v[1];
    if(minimum<0||minimum>MAX_TEXT_LENGTH||text_length<0||text_length>MAX_TEXT_LENGTH||n!=(usz)text_length+2)return -1;
    bool upper=false,lower=false,digit=false,punctuation=false;
    for(usz i=0;i<(usz)text_length;i++){
        long value=v[i+2];if(value<0||value>127)return -1;
        if(value>='A'&&value<='Z')upper=true;
        if(value>='a'&&value<='z')lower=true;
        if(value>='0'&&value<='9')digit=true;
        if((value>=33&&value<=47)||(value>=58&&value<=64)||(value>=91&&value<=96)||(value>=123&&value<=126))punctuation=true;
    }
    return (text_length>=minimum&&upper&&lower&&digit&&punctuation)?1:0;
}
