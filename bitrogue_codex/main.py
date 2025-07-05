from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, String
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel
from typing import List

app = FastAPI()

# --- 1. 데이터베이스 설정 ---
# 데이터베이스 파일 경로를 지정합니다. SQLite를 사용합니다.
DATABASE_URL = "sqlite:///./codex.db" 
# SQLAlchemy 엔진을 생성합니다. connect_args는 스레드 관련 설정을 위함입니다.
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
# 데이터베이스 세션 생성을 위한 SessionLocal 클래스를 만듭니다.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# SQLAlchemy 모델의 베이스 클래스를 생성합니다.
Base = declarative_base()


# --- 2. Pydantic 모델 정의 ---
# API의 입출력 데이터 형식을 정의합니다. 타입 힌트를 통해 데이터 유효성을 검사합니다.
class ItemBase(BaseModel):
    code: str
    name: str
    description: str
    effect: str

class ItemCreate(ItemBase):
    pass

# API 응답에 사용될 모델입니다. orm_mode=True는 SQLAlchemy 모델과 연동되도록 합니다.
class Item(ItemBase):
    class Config:
        orm_mode = True


# --- 3. SQLAlchemy 모델 (DB 테이블) 정의 ---
# 데이터베이스의 'items' 테이블 구조를 정의하는 클래스입니다.
class DBItem(Base):
    __tablename__ = "items"
    code = Column(String, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    # effect는 "타입:값" 형태의 문자열로 효과를 저장합니다. (예: "health:1", "speed:20")
    effect = Column(String)


# --- 4. 데이터베이스 의존성 주입 ---
# API가 호출될 때마다 독립적인 데이터베이스 세션을 생성하고, 끝나면 닫아주는 함수입니다.
# 이 방식을 통해 데이터베이스 연결을 안전하게 관리할 수 있습니다.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# --- 5. 서버 시작 이벤트 처리 ---
# FastAPI 앱이 시작될 때 한 번만 실행되는 함수입니다.
@app.on_event("startup")
def on_startup():
    # 정의된 SQLAlchemy 모델을 바탕으로 데이터베이스에 테이블을 생성합니다.
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    # 만약 아이템이 하나도 없다면, 샘플 데이터를 추가합니다.
    if db.query(DBItem).count() == 0:
        sample_items = [
            DBItem(code="HP001", name="Health Potion", description="Recovers 1 HP.", effect="health:1"),
            DBItem(code="SP001", name="Speed Boots", description="Increases movement speed by 20%.", effect="speed:20"),
            DBItem(code="DMG001", name="Power Glove", description="Increases projectile damage by 1.", effect="damage:1")
        ]
        db.add_all(sample_items)
        db.commit()
    db.close()


# --- 6. API 엔드포인트 정의 ---

# [신규] 모든 아이템 목록을 조회하는 API
@app.get("/items", response_model=List[Item])
def get_all_items(db: Session = Depends(get_db)):
    """
    데이터베이스에 있는 모든 아이템의 목록을 반환합니다.
    - response_model=List[Item]: 이 함수의 반환값이 Item 모델의 리스트 형태임을 명시합니다.
    - db: Session = Depends(get_db): get_db 함수를 통해 데이터베이스 세션을 주입받습니다.
    """
    items = db.query(DBItem).all()
    return items

# 특정 아이템을 코드로 조회하는 API (기존 코드 개선)
@app.get("/item/{code}", response_model=Item)
def get_item(code: str, db: Session = Depends(get_db)):
    """
    주어진 코드로 특정 아이템을 조회합니다.
    """
    item = db.query(DBItem).filter(DBItem.code == code).first()
    if item is None:
        # 아이템이 없으면 404 에러를 발생시킵니다.
        raise HTTPException(status_code=404, detail="Item not found")
    return item

# 아이템을 추가하는 API (기존 코드 개선)
@app.post("/add_item", response_model=Item)
def add_item(item: ItemCreate, db: Session = Depends(get_db)):
    """
    새로운 아이템을 데이터베이스에 추가합니다.
    - item: ItemCreate: 요청 본문(body)이 ItemCreate 모델의 형식이어야 함을 명시합니다.
    """
    db_item = DBItem(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item