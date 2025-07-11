from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, Session, relationship
from datetime import datetime
from pydantic import BaseModel
from passlib.context import CryptContext

app = FastAPI()

# 1. Database Setup
DATABASE_URL = "sqlite:///./bitrogue.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 3. Database Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 4. Pydantic Models (Data Schemas)
class UserCreate(BaseModel):
    username: str
    password: str

class User(BaseModel):
    id: int
    username: str

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
    user: User # Include user info in the score response

    class Config:
        orm_mode = True

# 5. SQLAlchemy Models (Database Tables)
class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
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

# 6. Create Database Tables
Base.metadata.create_all(bind=engine)

# 7. API Endpoints

@app.post("/register", response_model=User, status_code=status.HTTP_201_CREATED)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = pwd_context.hash(user.password)
    new_user = UserModel(username=user.username, hashed_password=hashed_password)
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
    return db_score

@app.get("/leaderboard", response_model=list[Score])
def get_leaderboard(db: Session = Depends(get_db)):
    # Query scores and join with user data, order by score descending
    scores = (
        db.query(ScoreModel)
        .join(UserModel)
        .order_by(ScoreModel.score.desc())
        .limit(10)
        .all()
    )
    return scores