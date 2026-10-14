module best_time_to_buy_and_sell_stock;

// Maximum profit from one buy followed by one sell.
fn long best_time_to_buy_and_sell_stock(long* prices, usz length)
    @export("best_time_to_buy_and_sell_stock")
{
    if (length > 4096) return -1;
    if (length == 0) return 0;
    long minimum = prices[0];
    long best = 0;
    for (usz day = 0; day < length; day++) {
        long price = prices[day];
        if (price < 0 || price > 1000000000) return -1;
        if (price < minimum) minimum = price;
        long profit = price - minimum;
        if (profit > best) best = profit;
    }
    return best;
}
