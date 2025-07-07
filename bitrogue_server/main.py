from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, Session, relationship
from datetime import datetime
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests

app = FastAPI()

# 1. SQLite DB 연결
DATABASE_URL = "sqlite:///./bitrogue.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic Models
class UserCreate(BaseModel):
    google_id: str
    name: str
    email: str

class User(UserCreate):
    id: int

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

    class Config:
        orm_mode = True


# SQLAlchemy Models
class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, unique=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
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


# 3. 테이블 생성
Base.metadata.create_all(bind=engine)

# 4. API Endpoints
CLIENT_ID = "YOUR_GOOGLE_CLIENT_ID" # TODO: Replace with your Google Client ID

@app.post("/users", response_model=User)
def create_user(token: str, db: Session = Depends(get_db)):
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), CLIENT_ID)

        userid = idinfo['sub']
        name = idinfo['name']
        email = idinfo['email']

        db_user = db.query(UserModel).filter(UserModel.google_id == userid).first()
        if db_user:
            return db_user
        else:
            new_user = UserModel(google_id=userid, name=name, email=email)
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            return new_user
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid Google ID Token")


@app.post("/scores", response_model=Score)
def create_score(score: ScoreCreate, user_id: int, db: Session = Depends(get_db)):
    db_score = ScoreModel(**score.dict(), user_id=user_id)
    db.add(db_score)
    db.commit()
    db.refresh(db_score)
    return db_score


@app.get("/leaderboard")
def get_leaderboard(db: Session = Depends(get_db)):
    scores = db.query(ScoreModel).order_by(ScoreModel.score.desc()).limit(10).all()
    return scores
