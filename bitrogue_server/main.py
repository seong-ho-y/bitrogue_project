from fastapi import FastAPI
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import sessionmaker, declarative_base
from datetime import datetime

app = FastAPI()

# 1. SQLite DB 연결
DATABASE_URL = "sqlite:///./bitrogue.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

# 2. Scores 테이블 모델 정의
class Score(Base):
    __tablename__ = "scores"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, index=True)
    score = Column(Integer)
    items = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

# 3. 테이블 생성
Base.metadata.create_all(bind=engine)

# 4. 테스트 API - DB에 데이터 추가
@app.post("/submit_score")
def submit_score(username: str, score: int, items: str):
    db = SessionLocal()
    new_score = Score(username=username, score=score, items=items)
    db.add(new_score)
    db.commit()
    db.refresh(new_score)
    db.close()
    return {"message": "Score submitted!", "id": new_score.id}

# 5. 테스트 API - 점수 조회
@app.get("/leaderboard")
def get_leaderboard():
    db = SessionLocal()
    scores = db.query(Score).order_by(Score.score.desc()).limit(10).all()
    db.close()
    return scores
