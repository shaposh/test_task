import psycopg2
import telebot
import openpyxl
import pandas as pd
from yaml import safe_load


def get_config(path):
    with open(path, 'r') as stream:
        config = safe_load(stream)
    return config

bot = telebot.TeleBot(get_config('conf.yml')['BOT_TOKEN'])

def get_data(filename, param):
    try:
        connection = psycopg2.connect(get_config('conf.yml')['CONNECTION_STRING'])
    except Exception as E:
        print ("ERROR:", E)
        exit(-1)

    cursor = connection.cursor()
    cursor.execute(f"SELECT * FROM public.overdue_report('{param}')")
    records = cursor.fetchall()

    columns = ('Регион', 'МО', 'GTIN', 'Серия', 'Остаток', 'Просрочка дни')
    df = pd.DataFrame(records, columns=columns)
    if len(df)==0:
        return -1

    writer = pd.ExcelWriter(filename)
    df.to_excel(writer, sheet_name='Sheet 1', index=False)
    for column in df:
        column_width = max(df[column].astype(str).map(len).max(), len(column))
        col_idx = df.columns.get_loc(column)
        writer.sheets['Sheet 1'].set_column(col_idx, col_idx, column_width)
    writer.close()
    return 0

@bot.message_handler(commands=['report'])
def get_text_messages(message):
    input_data = message.text.split()
    param = input_data[1] if len(input_data)!= 1 else 'SUB'

    file_name = 'reports/report_' + param + '.xlsx'
    try:
       status = get_data(file_name, param)
    except:
        file_name = 'reports/report.xlsx'
        status = get_data(file_name, param)
    if status == 0:
        with open(file_name, 'rb') as f:
            bot.send_document(message.chat.id, f)
    else:
        bot.send_message(message.chat.id, 'Данные по Вашему запросу отсутствуют')

@bot.message_handler(content_types='text')
def message_reply(message):
    out_message = "Для получения отчетов используйте команду /report с одним из параметров:\n" \
                  "/report SUB \n" \
                  "/report MO \n" \
                  "/report GTIN \n" \
                  "/report SER \n" \
                  "/report SUB_NOW \n" \
                  "/report MO_NOW \n" \
                  "/report GTIN_NOW \n" \
                  "/report SER_NOW \n"
    bot.send_message(message.chat.id, out_message)


if __name__ == '__main__':
    bot.infinity_polling()