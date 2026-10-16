module two_pointer;

fn long two_pointer(long* input, usz length) @export("two_pointer") {
    if (input == null || length < 2 || length > 258) return -2;
    long n=input[0], target=input[1];
    if(n<0||n>256||length!=(usz)(n+2)||target < -2147483648||target>2147483647)return -2;
    for(usz i=0;i<(usz)n;i++)if(input[i+2]<-2147483648||input[i+2]>2147483647||(i>0&&input[i+1]>input[i+2]))return -2;
    usz left=0,right=n>0?(usz)n-1:0;
    while(left<right){long sum=input[left+2]+input[right+2];if(sum==target)return (long)(left*256+right);if(sum<target)left++;else right--;}
    return -1;
}
