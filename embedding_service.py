from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn

app = FastAPI()
# "EmbeddingApiUrl": "http://127.0.0.1:8000/embed"
# Load mô hình 1 lần duy nhất khi khởi động API
print("Đang tải mô hình BAAI/bge-m3...")
# Dùng device="cuda" nếu máy bạn có GPU, ngược lại để "cpu"
model = SentenceTransformer('BAAI/bge-m3', device="cpu") 
print("Tải mô hình thành công. Sẵn sàng nhận Request!")

class QueryRequest(BaseModel):
    text: str

@app.post("/embed")
def get_embedding(request: QueryRequest):
    # Trả về Vector y hệt như code cũ của bạn
    vector = model.encode(request.text).tolist()
    return {"vector": vector}

if __name__ == "__main__":
    # Chạy server ở cổng 8000
    uvicorn.run(app, host="127.0.0.1", port=8000)