FROM python:latest

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY reports reports
COPY data data

COPY data/ETL.xlsx data/ETL.xlsx
COPY conf.yml conf.yml
COPY etl_import.py etl_telegram.py ./

CMD python etl_import.py && python etl_telegram.py