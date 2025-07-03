from fastapi import FastAPI
from sqlalchemy import create_engine, Column, String
from sqlalchemy.orm import sessionmaker, declarative_base

app = FastAPI()

# DB 연결
DATABASE_URL = "sqlite:///./codex.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

# Items 테이블 모델
class Item(Base):
    __tablename__ = "items"
    code = Column(String, primary_key=True, index=True)
    name = Column(String)
    description = Column(String)
    effect = Column(String)

# 테이블 생성
Base.metadata.create_all(bind=engine)

# 샘플 데이터 삽입 API (개발용)
@app.post("/add_item")
def add_item(code: str, name: str, description: str, effect: str):
    db = SessionLocal()
    item = Item(code=code, name=name, description=description, effect=effect)
    db.add(item)
    db.commit()
    db.refresh(item)
    db.close()
    return {"message": f"Item {code} added."}

# 아이템 조회 API
@app.get("/item/{code}")
def get_item(code: str):
    db = SessionLocal()
    item = db.query(Item).filter(Item.code == code).first()
    db.close()
    if item:
        return {
            "code": item.code,
            "name": item.name,
            "description": item.description,
            "effect": item.effect
        }
    else:
        return {"message": "Item not found."}
