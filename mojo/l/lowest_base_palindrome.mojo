fn base_pal(number:Int64,base:Int64)->Bool:
    if number<=1:return True
    if number%base==0:return False
    var rem=number;var reversed:Int64=0
    while rem>0:reversed=reversed*base+rem%base;rem/=base
    return reversed==number
@export("lowest_base_palindrome")
fn lowest_base_palindrome(n:Int64) abi("C")->Int64:
    if n<0 or n>64:return -1
    var b:Int64=2
    while not base_pal(n,b):b+=1
    return b
