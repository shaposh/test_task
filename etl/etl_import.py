import pandas
import psycopg2
import time
from yaml import safe_load
import openpyxl

def get_config(path):
    with open(path, 'r') as stream:
        config = safe_load(stream)
    return config

def import_excel():

    oper_time = time.time()
    try:
        print ("Open excel file")
        data_frame = pandas.read_excel(get_config('conf.yml')['XLS_FILENAME'], engine='openpyxl', header=3, skiprows=[4], parse_dates=True)
    except Exception as E:
        print ("ERROR:", E)
        exit(-1)
    print ("  SUCCESS at", round(time.time() - oper_time, 2), "sec")
    print ()

    oper_time = time.time()
    try:
        print ("Connect to database")
        connection = psycopg2.connect(get_config('conf.yml')['CONNECTION_STRING'])
    except Exception as E:
        print ("ERROR:", E)
        exit(-2)
    print ("  SUCCESS at", round(time.time() - oper_time, 2), "sec")
    print ()

    cursor = connection.cursor()
    if get_config('conf.yml')['CLEAR_TABLE_BEFORE_IMPORT']:
        print ("Clear table")
        try:
            oper_time = time.time()
            cursor.callproc("overdue_clear")
            connection.commit()
        except Exception as E:
            connection.rollback()
            print ("ERROR:", E)
            exit(-3)
        print ("  SUCCESS at", round(time.time() - oper_time, 2), "sec")
    else:
        print ("Clear table skipped")
    print ()

    try:
        print ("Import records")
        row_id = 0
        for row in data_frame.iterrows():
            subject_value = str(row[1]['Субъект РФ'])
            mo_value = str(row[1]['МО'])
            inn_value = str(row[1]['ИНН'])
            status_value = str(row[1]['Статус'])
            outtype_value = str(row[1]['Тип вывода из оборота'])
            gtin_value = str(row[1]['ГТИН'])
            ser_value = str(row[1]['Серия'])
            package_dosage_value = int(row[1]['Дозы\n(количество доз в упаковке (флаконе))'])
            package_number_value = int(row[1]['Количество\nУпаковок'])
            dosage_number_value = int(row[1]['Количество\nДоз'])

            expdate_items = row[1]['Срок годности'].split(".")
            expdate_value = expdate_items[2] + "-" + expdate_items[1] + "-" + expdate_items[0]

            overdays_value = int(row[1]['Просрочено дней'])
            cursor.execute("CALL overdue_import(%(i_subject)s, %(i_mo)s, %(i_inn)s"
                           ", %(i_status)s, %(i_outtype)s"
                           ", %(i_gtin)s, %(i_ser)s"
                           ", %(i_package_dosage)s, %(i_package_number)s"
                           ", %(i_dosage_number)s"
                           ", %(i_expdate)s"
                           ", %(i_overdays)s)",
                         {'i_subject': subject_value, 'i_mo': mo_value, 'i_inn': inn_value
                             , 'i_status': status_value, 'i_outtype': outtype_value
                             , 'i_gtin': gtin_value, 'i_ser': ser_value
                             , 'i_package_dosage': package_dosage_value, 'i_package_number': package_number_value
                             , 'i_dosage_number': dosage_number_value
                             , 'i_expdate': expdate_value, 'i_overdays': overdays_value})
            row_id = row_id + 1
        connection.commit()
    except Exception as E:
        connection.rollback()
        print ("ERROR:", E)
        exit(-4)
    print ("  SUCCESS at", round(time.time() - oper_time, 2), "sec")
    print (str(row_id) + " records imported/updated")
    return

if __name__ == '__main__':
    import_excel()
