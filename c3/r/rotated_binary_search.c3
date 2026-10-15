module rotated_binary_search;

fn long rotated_binary_search(long* input, usz length) @export("rotated_binary_search") {
    if(input==null||length<2||input[0]<0||input[0]>256)return -2;usz n=(usz)input[0];if(length!=n+2)return -2;if(n==0)return -1;
    long key=input[n+1];if(key<-2147483648||key>2147483647)return -2;usz drops=0;
    for(usz i=0;i<n;i++){if(input[i+1]<-2147483648||input[i+1]>2147483647)return -2;if(i>0&&input[i]>input[i+1])drops++;}
    if(drops>1||(drops==1&&input[n]>input[1]))return -2;
    usz left=0;
    usz right=n-1;
    while(left<=right){usz middle=left+(right-left)/2;long mid=input[middle+1];if(key==mid)return (long)middle;
        if(input[left+1]==mid&&mid==input[right+1]){left++;if(right==0)break;right--;continue;}
        if(input[left+1]<=mid){if(input[left+1]<=key&&key<mid){if(middle==0)break;right=middle-1;}else{left=middle+1;}}
        else if(mid<key&&key<=input[right+1]){left=middle+1;}
        else{if(middle==0)break;right=middle-1;}
    }
    return -1;
}
