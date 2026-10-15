module max_product_of_three;
const long INVALID_RESULT = -9223372036854775807l - 1l;

fn long max_product_of_three(long* input, usz length) @export("max_product_of_three") {
    if (input == null || length < 1 || input[0] < 3 || input[0] > 128 || length != (usz)input[0] + 1) return INVALID_RESULT;
    usz n = (usz)input[0];
    for (usz i = 0; i < n; i++) if (input[i + 1] < -1000 || input[i + 1] > 1000) return INVALID_RESULT;
    long max1=input[1],max2=-1001,max3=-1001,min1=input[1],min2=1001;
    for (usz i=1;i<n;i++) { long value=input[i+1]; if(value>max1){max3=max2;max2=max1;max1=value;}else if(value>max2){max3=max2;max2=value;}else if(value>max3)max3=value; if(value<min1){min2=min1;min1=value;}else if(value<min2)min2=value; }
    long product1=max1*max2*max3;long product2=max1*min1*min2;return product1>product2?product1:product2;
}
