from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, String, Integer, Float
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel
from typing import List
import requests

app = FastAPI()

# --- 데이터베이스 설정 ---
# 데이터베이스 파일 경로, SqLite
DATABASE_URL = "sqlite:///./codex.db" 
# SQLAlchemy 엔진을 생성.
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
# 데이터베이스 세션 생성을 위한 SessionLocal 클래스
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# SQLAlchemy 모델의 베이스 클래스를 생성
Base = declarative_base()


# --- Pydantic 모델 정의 ---
# API의 입출력 데이터 형식을 정의
# 데이터 유효성 검사
class ItemBase(BaseModel):
    code: str
    name: str
    description: str
    effect: str

class ItemCreate(ItemBase):
    pass

# API 응답에 사용될 모델
# orm_mode=True는 SQLAlchemy 모델과 연동
class Item(ItemBase):
    class Config:
        orm_mode = True

class WeaponBase(BaseModel):
    code: str
    name: str
    description: str
    unlock_score: int
    max_ammo: int # New field
    reload_time: float # New field

class WeaponCreate(WeaponBase):
    pass

class Weapon(WeaponBase):
    class Config:
        orm_mode = True


# --- SQLAlchemy 모델 (DB 테이블) 정의 ---
# 데이터베이스의 'items' 테이블 구조를 정의하는 클래스
class DBItem(Base):
    __tablename__ = "items"
    code = Column(String, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    # effect는 "타입:값" 형태의 문자열로 효과를 저장
    effect = Column(String)

class DBWeapon(Base):
    __tablename__ = "weapons"
    code = Column(String, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    unlock_score = Column(Integer)
    max_ammo = Column(Integer) # New column
    reload_time = Column(Float) # New column


# --- 데이터베이스 의존성 주입 ---
# API가 호출될 때마다 독립적인 데이터베이스 세션을 생성하고, 끝나면 닫아주는 함수
# 이 방식을 통해 데이터베이스 연결을 안전하게 관리
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# --- 서버 시작 이벤트 처리 ---
# FastAPI 앱이 시작될 때 한 번만 실행되는 함수
@app.on_event("startup")
def on_startup():
    # 정의된 SQLAlchemy 모델을 바탕으로 데이터베이스에 테이블을 생성
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    # 만약 아이템이 하나도 없다면, 샘플 데이터를 추가
    if db.query(DBItem).count() == 0:
        sample_items = [
            DBItem(code="HP001", name="A", description="체력 1 회복.", effect="health:1"),
            DBItem(code="SP001", name="B", description="이동 속도 20% 증가.", effect="speed:20"),
            DBItem(code="DMG001", name="C", description="발사체 공격력 1 증가.", effect="damage:1"),
            DBItem(code="DMG002", name="D", description="무기 공격력 15% 증가. 탄속 10% 감소.", effect="damage_percent:15,projectile_speed_percent:-10"),
            DBItem(code="OVL001", name="E", description="다음 5회 공격에 한해 공격력 50% 증가. 이후 10초간 공격력 20% 감소.", effect="overload_damage:5,overload_duration:10"),
            DBItem(code="FIR001", name="F", description="연사력 15% 증가. 탄약 소모량 10% 증가.", effect="fire_rate_percent:15,ammo_cost_percent:10"),
        ]
        db.add_all(sample_items)
        db.commit()

    if db.query(DBWeapon).count() == 0:
        sample_weapons = [
            DBWeapon(code="W001", name="Standard", description="A reliable standard-issue weapon.", unlock_score=0, max_ammo=100, reload_time=2.0),
            DBWeapon(code="W006", name="Shotgun", description="Fires multiple projectiles in a spread.", unlock_score=500, max_ammo=10, reload_time=3.0),
            DBWeapon(code="W002", name="Charge Shot", description="Hold to charge for a powerful blast.", unlock_score=1000, max_ammo=5, reload_time=4.0),
            DBWeapon(code="W003", name="Crack Shot", description="Splits into four projectiles mid-flight.", unlock_score=2000, max_ammo=15, reload_time=3.5),
            DBWeapon(code="W004", name="Laser", description="Pierces through multiple enemies.", unlock_score=3000, max_ammo=20, reload_time=5.0),
            DBWeapon(code="W005", name="Proximity Mine", description="Explodes after a short delay.", unlock_score=4000, max_ammo=3, reload_time=2.5)
        ]
        db.add_all(sample_weapons)
        db.commit()
    db.close()


# --- API 엔드포인트 정의 ---

# 모든 아이템 목록을 조회하는 API
@app.get("/items", response_model=List[Item])
def get_all_items(db: Session = Depends(get_db)):
    """
    데이터베이스에 있는 모든 아이템의 목록을 반환합니다.
    - response_model=List[Item]: 이 함수의 반환값이 Item 모델의 리스트 형태임을 명시합니다.
    - db: Session = Depends(get_db): get_db 함수를 통해 데이터베이스 세션을 주입받습니다.
    """
    items = db.query(DBItem).all()
    return items

@app.get("/weapons", response_model=List[Weapon])
def get_all_weapons(db: Session = Depends(get_db)):
    weapons = db.query(DBWeapon).all()
    return weapons

# 특정 아이템을 코드로 조회하는 API
@app.get("/item/{code}", response_model=Item)
def get_item(code: str, db: Session = Depends(get_db)):
    """
    주어진 코드로 특정 아이템을 조회합니다.
    """
    item = db.query(DBItem).filter(DBItem.code == code).first()
    if item is None:
        # 아이템이 없으면 404 에러
        raise HTTPException(status_code=404, detail="Item not found")
    return item

# 아이템을 추가하는 API
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

    try:
        log_data = {
            "item_code": db_item.code,
            "user_id": 1,  
            "score_at_pickup": 0 
        }
        requests.post("http://192.168.45.245:8000/log_item_pickup", json=log_data)
    except requests.exceptions.ConnectionError as e:
        print(f"Could not connect to bitrogue_server: {e}")
    except Exception as e:
        print(f"An error occurred while logging item pickup: {e}")

    return db_item