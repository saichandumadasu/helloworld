from fastapi import FastAPI 

app = FastAPI()

@app.get("/middle")
def middle():
    return {"message": "Middle"}