# test python task №2
# Вы продукт-менеджер и в настоящее время возглавляете команду по
# разработке нового продукта. К сожалению, последняя версия вашего
# продукта не прошла проверку качества. Поскольку каждая версия
# разрабатывается на основе предыдущей версии, все версии после
# сломанной версии тоже сломаны
# Предположим, у вас есть n версий [1, 2, ..., n] и вы хотите найти
# первую сломанную версию, из-за которой все последующие будут сломаны
# Вам предоставляется bool API isBrokenVersion (версия), который
# возвращает, является ли версия сломанной. Реализуйте функцию для
# поиска первой сломанной версии
# Вы должны свести к минимуму количество обращений к API

# Shaposhnikov A.V.; 2023-06-29
# Сложность По Времени = O(log n)
# Сложность По Памяти  = O(1)

import math

VALID_VERSIONS = (
    True,  True,  True,  True,  True,  True,  True,  True,
    True,  True,  True,  True,  False, False, False, False,
    False, False, False, False, False, False, False, False
)

def isBrokenVersion(versionNumber: int) -> bool:
    return not VALID_VERSIONS[versionNumber]

def solve(tuple_length: int) -> int:
    item_id = 0
    last_item_id = tuple_length - 1
    while item_id < last_item_id:
        middle_item_id = math.floor((item_id + last_item_id)/2)
        if isBrokenVersion(middle_item_id):
            last_item_id = middle_item_id
        else:
            item_id = middle_item_id + 1
    return item_id

if __name__ == '__main__':
    print(solve(len(VALID_VERSIONS)))