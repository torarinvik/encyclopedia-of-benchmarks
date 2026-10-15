module palindrome_partitioning_all_partitions;

const usz MAX_LENGTH=12, OUT_CAP=16000;
struct Context { long* text; usz length; usz[12] ends; long[16000] packed; usz used; usz partitions; }

fn bool is_palindrome(Context* ctx,usz start,usz end){while(start<end){if(ctx.text[start]!=ctx.text[end-1])return false;start++;end--;}return true;}
fn void enumerate(Context* ctx,usz start,usz depth){
    if(start==ctx.length){ctx.partitions++;ctx.packed[ctx.used++]=(long)depth;for(usz i=0;i<depth;i++)ctx.packed[ctx.used++]=(long)ctx.ends[i];return;}
    for(usz end=start+1;end<=ctx.length;end++)if(is_palindrome(ctx,start,end)){ctx.ends[depth]=end;enumerate(ctx,end,depth+1);}
}
fn long palindrome_partitioning_all_partitions(long* input,usz length,char* output,usz capacity) @export("palindrome_partitioning_all_partitions"){
    if(input==null||length<1||input[0]<0||input[0]>(long)MAX_LENGTH||length!=(usz)input[0]+1)return -1;
    usz n=(usz)input[0];for(usz i=0;i<n;i++)if(input[i+1]<0||input[i+1]>127)return -1;
    Context ctx;ctx.text=input+1;ctx.length=n;ctx.used=1;ctx.partitions=0;enumerate(&ctx,0,0);ctx.packed[0]=(long)ctx.partitions;
    usz required=ctx.used*8;if(output==null||capacity<required)return -2;
    for(usz i=0;i<ctx.used;i++){ulong bits=(ulong)ctx.packed[i];for(usz byte=0;byte<8;byte++)output[i*8+byte]=(char)(bits>>(8*byte));}
    return (long)required;
}
