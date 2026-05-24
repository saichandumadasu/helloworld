from fastapi import FastAPI, HTTPException
import httpx


app = FastAPI()

@app.get("/middle")
def middle():
    return {"message": "Middle"}