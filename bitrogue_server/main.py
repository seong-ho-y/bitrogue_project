from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, Session, relationship
from datetime import datetime
from pydantic import BaseModel
from passlib.context import CryptContext

app = FastAPI()

# 1. DB 셋업
DATABASE_URL = "sqlite:///./bitrogue.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. 비번 셋업
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 3. DB 의존성
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 4. Pydantic Models
class UserCreate(BaseModel):
    username: str
    password: str

class User(BaseModel):
    id: int
    username: str
    high_score: int

    class Config:
        orm_mode = True

class ScoreCreate(BaseModel):
    score: int
    weapon: str
    items: str

class Score(ScoreCreate):
    id: int
    user_id: int
    timestamp: datetime
    user: User

    class Config:
        orm_mode = True

class ItemPickupLog(BaseModel):
    item_code: str
    user_id: int
    score_at_pickup: int

class ItemPickupLogResponse(ItemPickupLog):
    id: int
    timestamp: datetime

    class Config:
        orm_mode = True

# 5. SQLAlchemy Models
class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    high_score = Column(Integer, default=0) # 새로운 하이스코어 Column
    created_at = Column(DateTime, default=datetime.utcnow)
    scores = relationship("ScoreModel", back_populates="user")

class ScoreModel(Base):
    __tablename__ = "scores"
    id = Column(Integer, primary_key=True, index=True)
    score = Column(Integer)
    weapon = Column(String)
    items = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))
    user = relationship("UserModel", back_populates="scores")

class ItemPickupLogModel(Base):
    __tablename__ = "item_pickup_logs"
    id = Column(Integer, primary_key=True, index=True)
    item_code = Column(String, index=True)
    user_id = Column(Integer, index=True)
    score_at_pickup = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)

# 6. 데이터베이스 만들기
Base.metadata.create_all(bind=engine)

# 7. API Endpoints

@app.post("/register", response_model=User, status_code=status.HTTP_201_CREATED)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = pwd_context.hash(user.password)
    new_user = UserModel(username=user.username, hashed_password=hashed_password, high_score=0) # Initialize high_score
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/login", response_model=User)
def login_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.username == user.username).first()
    if not db_user or not pwd_context.verify(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return db_user

@app.post("/scores", response_model=Score)
def create_score(score: ScoreCreate, user_id: int, db: Session = Depends(get_db)):
    db_score = ScoreModel(**score.dict(), user_id=user_id)
    db.add(db_score)
    db.commit()
    db.refresh(db_score)

    # 하이스코어 갱신
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user and score.score > user.high_score:
        user.high_score = score.score
        db.add(user)
        db.commit()
        db.refresh(user)

    return db_score

@app.get("/leaderboard", response_model=list[Score])
def get_leaderboard(db: Session = Depends(get_db)):
    # 오름차순으로 리더보드 갱신
    scores = (
        db.query(ScoreModel)
        .join(UserModel)
        .order_by(ScoreModel.score.desc())
        .limit(10)
        .all()
    )
    return scores

@app.get("/users/{user_id}/high_score", response_model=int)
def get_user_high_score(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user.high_score

@app.post("/log_item_pickup", response_model=ItemPickupLogResponse, status_code=status.HTTP_201_CREATED)
def log_item_pickup(log: ItemPickupLog, db: Session = Depends(get_db)):
    db_log = ItemPickupLogModel(**log.dict())
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log
