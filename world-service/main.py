from fastapi import FastAPI

app = FastAPI()


@app.get("/world")
def world():
    return {"message": "World"}
