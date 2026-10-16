module min_palindromic_insert;
const usz MAX_N=256;
const usz MAX_OUTPUT=527;
fn usz write_i64(char* out,usz pos,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[pos++]=(char)(bits&255);bits>>=8;}return pos;}
fn long min_palindromic_insert(long* input,usz length,char* output,usz capacity) @export("min_palindromic_insert") {
    if(input==null||length<1||length>MAX_N+1)return -1;
    long n_value=input[0];if(n_value<1||n_value>(long)MAX_N||length!=(usz)n_value+1)return -1;
    usz n=(usz)n_value;uint8[MAX_N] chars;
    for(usz i=0;i<n;i++){long value=input[i+1];if(value<32||value>126)return -1;chars[i]=(uint8)value;}
    ushort[65536] dp=zeroed;
    for(usz span=2;span<=n;span++)for(usz left=0;left+span<=n;left++){
        usz right=left+span-1;usz at=left*MAX_N+right;
        if(chars[left]==chars[right]){if(span>2)dp[at]=dp[(left+1)*MAX_N+right-1];}
        else{ushort a=dp[(left+1)*MAX_N+right],b=dp[left*MAX_N+right-1];dp[at]=(ushort)((a<b?a:b)+1);}
    }
    usz insertions=(usz)dp[n-1],palindrome_length=n+insertions;
    uint8[511] palindrome;usz left=0,right=n-1,out_left=0,out_right=palindrome_length-1;
    while(left<=right){
        if(chars[left]==chars[right]){palindrome[out_left]=chars[left];palindrome[out_right]=chars[right];left++;if(right==0)break;right--;}
        else if(dp[(left+1)*MAX_N+right]<dp[left*MAX_N+right-1]){palindrome[out_left]=chars[left];palindrome[out_right]=chars[left];left++;}
        else{palindrome[out_left]=chars[right];palindrome[out_right]=chars[right];if(right==0)break;right--;}
        out_left++;if(out_right==0)break;out_right--;
    }
    char[MAX_OUTPUT] payload=zeroed;usz written=write_i64(&payload[0],0,(long)insertions);written=write_i64(&payload[0],written,(long)palindrome_length);
    for(usz i=0;i<palindrome_length;i++)payload[written+i]=(char)palindrome[i];written+=palindrome_length;
    if(output==null||capacity<written)return -2;for(usz i=0;i<written;i++)output[i]=payload[i];return (long)written;
}
