module celsius_to_fahrenheit;

fn double celsius_to_fahrenheit(double celsius) @export("celsius_to_fahrenheit") {
    return (celsius * 9.0 / 5.0) + 32.0;
}
