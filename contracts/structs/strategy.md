## Chances, that random ticket would win corners is:

```python
def chances(took_out, points):
    x = took_out
    ans = 1
    for i in range(points):
        ans *= (x-i)/(99-i)
    return ans
```

`chances(20, 4) = x/99 * (x-1)/98 * (x-2)/97 * (x-3)/96 = 0.0012870659041498511`

Thus, for 5000 tickets it donna give us ~6.4 winning tickets. 

## Chances to win in crossing:
```python
chances(36, 8)
```
The chances are `0.00017675343168759513`

Thus, for 5000 tickets it's going to give us ~0.88 winning tickets.

## Chances to win jackpot:

```python
chances(55, 24)
```

The chances are `0.0000000410456381072074707049322306665062`




### То есть, в чём юмор:
нам даны *количество юзеров* (ожидаемая вероятность выигрыша) и *количество клеток*, по которым производится розыгрыш.
Нужно посчитать *количество бочёнков*, чтобы ожидаемая вероятность выигрыша была равна заданной.




В случае 4х бочёнков:

`chances(x) = `

