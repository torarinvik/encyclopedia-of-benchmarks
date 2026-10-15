/// Validate an even-length decimal digit array using Luhn's checksum.
export fn luhn_validate(input:[*]const i64,length:usize)i64{
 if(length<1)return -1;const v=input[0..length];const n=v[0];if(n<2 or n>64 or @mod(n,2)!=0 or length!=@as(usize,@intCast(n))+1)return -1;
 var sum:i64=0;for(0..@intCast(n))|i|{var d=v[i+1];if(d<0 or d>9)return -1;if(i%2==0){d*=2;if(d>9)d-=9;}sum+=d;}return if(@mod(sum,10)==0)1 else 0;
}
