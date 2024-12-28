FROM python:3.9-slim

WORKDIR /home/tanerbilgin94/devops-case

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
~                        
