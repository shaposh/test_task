# test python task №1
# Дан массив целых чисел nums и целое число target
# Необходимо вернуть индексы двух чисел таких, чтобы их сумма равна
# target. Имеется ровно одно решение. Один и тот же элемент нельзя
# использовать дважды. Результат можно вернуть в любом порядке
# Необходимо предоставить анализ сложности по времени
# и памяти в нотации O.

# Shaposhnikov A.V.; 2023-06-29
# Сложность По Времени = O(n)
# Сложность По Памяти  = O(n)

from typing import List
def solve(items_list: List[int], target_summary_value: int) -> List[int]:
    dictionary_delta = dict()
    for item_number, item_value in enumerate(items_list):
        delta_value = target_summary_value - item_value
        if delta_value not in dictionary_delta:
            dictionary_delta[item_value] = item_number
        else:
            return [dictionary_delta[delta_value], item_number]
    return []

if __name__ == '__main__':
    # test Example №1
    print (solve([2, 7, 11, 15], 9))

    # test Example №2
    print (solve([3, 2, 4], 6))

    # test Example №3
    print(solve([3, 3], 6))

    # test Example №4
    print(solve([3, 3], 6))

