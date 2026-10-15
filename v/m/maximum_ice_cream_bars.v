module maximum_ice_cream_bars

// Buy the largest affordable prefix after sorting the prices.
@[export: 'maximum_ice_cream_bars']
pub fn maximum_ice_cream_bars(input &i64, length usize) i64 {
    if length < 1 || length > 257 { return -1 }
    unsafe {
        coins := input[0]
        count := int(length - 1)
        if coins < 0 || coins > 1_000_000 { return -1 }
        mut costs := [256]i64{}
        for index in 0 .. count {
            cost := input[index + 1]
            if cost < 1 || cost > 10_000 { return -1 }
            mut position := index
            for position > 0 && costs[position - 1] > cost {
                costs[position] = costs[position - 1]
                position--
            }
            costs[position] = cost
        }
        mut remaining := coins
        mut bought := i64(0)
        for index in 0 .. count {
            if costs[index] > remaining { break }
            remaining -= costs[index]
            bought++
        }
        return bought
    }
}
