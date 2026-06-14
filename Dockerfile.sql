FROM mcr.microsoft.com/mssql/server:2022-latest
USER root
RUN apt-get update && apt-get install -y python3
RUN echo "file_path = '/opt/mssql/bin/sqlservr'" > patch.py && \
    echo "with open(file_path, 'rb') as f: data = bytearray(f.read())" >> patch.py && \
    echo "pattern = b'\x00\x94\x35\x77'" >> patch.py && \
    echo "replacement = b'\x00\x80\x84\x1e'" >> patch.py && \
    echo "idx = data.find(pattern)" >> patch.py && \
    echo "if idx != -1:" >> patch.py && \
    echo "    data[idx:idx+4] = replacement" >> patch.py && \
    echo "    with open(file_path, 'wb') as f: f.write(data)" >> patch.py && \
    echo "    print('Da be khoa gioi han RAM thanh cong!')" >> patch.py && \
    echo "else:" >> patch.py && \
    echo "    print('Khong tim thay mau bytes.')" >> patch.py
RUN python3 patch.py
USER mssql